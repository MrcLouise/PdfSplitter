package com.mrc.pdf;

import com.mrc.config.AppConfig;
import com.mrc.db.DatabaseManager;
import com.mrc.model.BulkUploadConfig;
import com.mrc.model.FormattedReportData;
import com.mrc.model.Instruction;
import com.mrc.model.ReportData;
import com.mrc.model.ReportTemplate;
import org.apache.pdfbox.io.MemoryUsageSetting;
import org.apache.pdfbox.multipdf.PDFMergerUtility;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.text.PDFTextStripper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class PdfProcessor {

    private static final Logger log = LoggerFactory.getLogger(PdfProcessor.class);

    private static final Pattern TRIM_PATTERN = Pattern.compile("(?i)trim\\s*\\(\\s*([a-zA-Z0-9_]+)\\s*\\)");
    private static final Pattern FN_SQL_SPACES = Pattern.compile("\\s+");
    private static final Pattern FN_SQL_UNDERSCORES = Pattern.compile("_+");
    private static final Pattern FN_SQL_TRIM_EDGES = Pattern.compile("^_+|_+$");
    private static final Pattern CORE_PATTERN = Pattern.compile("^.*?(\\d{8})_(\\d+)_(.+?)_(\\d{6})$");

    // Load configuration, read submitted instructions, and split PDFs.
    public static void main(String[] args) {
        System.setProperty("pdfbox.fontcache", System.getProperty("java.io.tmpdir"));

        AppConfig config;
        try {
            config = new AppConfig();
        } catch (Exception e) {
            log.error("failed to load CONNECTION.XML", e);
            System.exit(1);
            return;
        }

        if (args.length < 1 || args[0] == null || args[0].trim().isEmpty()) {
            log.error("missing bulkUpload dir, usage: PROCESS <bulkUploadDir> [outputDir] [attachmentDir] [extraOutputDir]");
            System.exit(1);
        }

        String bulkUploadFolder = args[0].replace("\"", "").trim();
        String outputFolder = args.length >= 2 ? args[1].replace("\"", "").trim()
                : bulkUploadFolder + File.separator + "split";
        String attachmentFolder = args.length >= 3 ? args[2].replace("\"", "").trim() : null;
        String extraOutputFolder = args.length >= 4 ? args[3].replace("\"", "").trim() : null;

        File bulkDir = new File(bulkUploadFolder);
        if (!bulkDir.exists() || !bulkDir.isDirectory()) {
            log.error("bulk upload dir not found: " + bulkUploadFolder);
            System.exit(1);
        }

        File outDir = new File(outputFolder);
        if (!outDir.exists()) {
            outDir.mkdirs();
        }

        File extraOutputDir = null;
        if (extraOutputFolder != null && !extraOutputFolder.isEmpty()) {
            extraOutputDir = new File(extraOutputFolder);
            if (!extraOutputDir.exists()) {
                extraOutputDir.mkdirs();
            }
        }

        File attachmentDir = null;
        if (attachmentFolder != null && !attachmentFolder.isEmpty()) {
            attachmentDir = new File(attachmentFolder);
            if (!attachmentDir.exists() || !attachmentDir.isDirectory()) {
                log.warn("attachment dir not found: " + attachmentFolder);
                attachmentDir = null;
            }
        }

        log.info("start process, from " + bulkUploadFolder + " to " + outputFolder +
                (attachmentDir != null ? ", attachment=" + attachmentDir.getAbsolutePath() : "") +
                (extraOutputDir != null ? ", extraOutput=" + extraOutputDir.getAbsolutePath() : ""));

        int totalInstr = 0;
        int successInstr = 0;

        try (DatabaseManager db = new DatabaseManager()) {
            List<Instruction> instructions = db.loadInstructionsByStatus("SUBMITTED");
            totalInstr = instructions.size();
            log.info("found " + totalInstr + " submitted instructions");

            for (Instruction inst : instructions) {
                String templateId = inst.getTemplateId();
                String referenceNo = inst.getReferenceNo();

                log.info("handle " + templateId + "/" + referenceNo);

                Date startTime = new Date();
                boolean ok = processInstruction(db, bulkDir, outDir, extraOutputDir, attachmentDir, templateId, referenceNo, inst);
                Date endTime = new Date();
                if (ok) {
                    successInstr++;
                    db.updateInstructionStatus(templateId, referenceNo, "GENERATED", "SYSTEM", startTime, endTime);
                    log.info("done " + templateId + "/" + referenceNo);
                } else {
                    db.updateInstructionStatus(templateId, referenceNo, "FAILED", "SYSTEM", startTime, endTime);
                    log.error("failed " + templateId + "/" + referenceNo);
                }
            }
        } catch (Exception e) {
            log.error("process error", e);
            System.exit(1);
        }

        log.info("finished, success=" + successInstr + "/" + totalInstr);
        if (successInstr < totalInstr) {
            System.exit(1);
        }
        log.info("all instructions processed successfully");
    }

    // Process one instruction: locate the PDF, split pages, merge attachments, and copy to extra output.
    private static boolean processInstruction(DatabaseManager db, File bulkDir, File outDir, File extraOutputDir,
                                               File attachmentDir, String templateId, String referenceNo, Instruction inst) {
        try {
            ReportTemplate template = db.loadReportTemplate(templateId);
            if (template == null) {
                log.error("template not found: " + templateId);
                return false;
            }

            List<ReportData> reportDataList = db.loadReportDataByTemplateAndRef(templateId, referenceNo);
            if (reportDataList.isEmpty()) {
                log.warn("no report data for " + templateId + "/" + referenceNo);
                return false;
            }
            log.info("report data count=" + reportDataList.size());

            BulkUploadConfig config = db.loadBulkUploadConfig(templateId);
            if (config == null && !inst.isSingleUpload()) {
                log.error("no bulk upload config for " + templateId);
                return false;
            }
            if (config != null) {
                log.info("bulk upload config loaded for " + templateId);
            }

            List<FormattedReportData> formattedList = config != null
                    ? db.loadFormattedReportData(config, templateId, referenceNo)
                    : new ArrayList<>();
            Map<Integer, ReportData> reportDataBySeq = new HashMap<>();
            for (ReportData rd : reportDataList) {
                reportDataBySeq.put(rd.getSeqNo(), rd);
            }

            File pdfFile = findPdfFile(bulkDir, referenceNo);
            if (pdfFile == null) {
                log.error("pdf not found for referenceNo=" + referenceNo + " in " + bulkDir.getAbsolutePath());
                return false;
            }
            log.info("pdf=" + pdfFile.getAbsolutePath());

            String reportName = template.getReportName();
            if (reportName == null || reportName.trim().isEmpty()) {
                reportName = templateId;
            }
            reportName = reportName.replaceAll("[^a-zA-Z0-9\\-_.]", "_");

            File reportOutDir = new File(outDir, reportName);
            File refOutDir = new File(reportOutDir, referenceNo);
            if (!refOutDir.exists()) {
                refOutDir.mkdirs();
            } else {
                File[] existing = refOutDir.listFiles((dir, name) -> name.toLowerCase().endsWith(".pdf"));
                if (existing != null) {
                    for (File f : existing) {
                        f.delete();
                    }
                }
            }

            String reportNameSql = template.getReportNameSql();
            List<String> fields = extractFieldsFromReportNameSql(reportNameSql);
            if (!inst.isSingleUpload()) {
                if (reportNameSql == null || reportNameSql.trim().isEmpty()) {
                    log.error("empty ReportNameSQL");
                    return false;
                }
                log.info("reportNameSql=" + reportNameSql);
                log.info("fields=" + fields);
            }

            boolean ok;
            if (inst.isSingleUpload()) {
                log.info("single upload mode");
                ok = processSingleUpload(pdfFile, refOutDir, reportDataList, referenceNo);
            } else {
                ok = processPdf(pdfFile, refOutDir, reportOutDir, referenceNo, reportDataList, reportDataBySeq, formattedList, config, reportNameSql, fields, template);
            }

            if (ok && attachmentDir != null) {
                ok = mergeAttachments(refOutDir, attachmentDir, referenceNo, inst);
            }

            if (ok && extraOutputDir != null) {
                copyToExtraOutput(refOutDir, extraOutputDir, reportName, referenceNo);
            }

            return ok;

        } catch (Exception e) {
            log.error("error on " + templateId + "/" + referenceNo, e);
            return false;
        }
    }

    // Handle single-upload mode by copying the source PDF directly to the output folder.
    private static boolean processSingleUpload(File pdfFile, File refOutDir,
                                                List<ReportData> reportDataList,
                                                String referenceNo) throws IOException {
        if (reportDataList.size() != 1) {
            log.warn("single upload expects 1 report data record, got " + reportDataList.size());
        }

        ReportData reportData = reportDataList.get(0);
        String fileName = reportData.getFileName();
        if (fileName == null || fileName.trim().isEmpty()) {
            fileName = referenceNo + ".pdf";
        } else if (!fileName.toLowerCase().endsWith(".pdf")) {
            fileName = fileName.trim() + ".pdf";
        } else {
            fileName = fileName.trim();
        }

        File outputFile = new File(refOutDir, fileName);
        Files.copy(pdfFile.toPath(), outputFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
        log.info("single upload copied " + pdfFile.getName() + " -> " + outputFile.getName());
        return true;
    }

    // Split the PDF by page and match each page to a report data record.
    private static boolean processPdf(File pdfFile, File refOutDir, File parentOutDir,
                                       String referenceNo,
                                       List<ReportData> reportDataList,
                                       Map<Integer, ReportData> reportDataBySeq,
                                       List<FormattedReportData> formattedList,
                                       BulkUploadConfig config,
                                       String reportNameSql, List<String> fields,
                                       ReportTemplate template) throws IOException {
        int matched = 0;
        int unmatched = 0;
        int skipped = 0;

        try (PDDocument doc = PDDocument.load(pdfFile)) {
            int total = doc.getNumberOfPages();
            log.info("total pages=" + total);

            PDFTextStripper stripper = new PDFTextStripper();

            for (int i = 0; i < total; i++) {
                stripper.setStartPage(i + 1);
                stripper.setEndPage(i + 1);
                String text = stripper.getText(doc);

                FormattedReportData formattedMatch = findMatchByConfig(text, formattedList, config);
                if (formattedMatch == null) {
                    log.warn("page " + (i + 1) + " no config match");
                    unmatched++;
                    continue;
                }
                ReportData matchedData = reportDataBySeq.get(formattedMatch.getSeqNo());
                Map<String, String> fieldValues = buildFieldValuesFromReportData(matchedData, fields);

                String generatedName = generateFileName(reportNameSql, fieldValues);
                boolean isBlankPage = isAllFieldsEmpty(fieldValues) && text.trim().length() <= 5;
                if (isBlankPage) {
                    log.info("skip blank page " + (i + 1));
                    skipped++;
                    continue;
                }

                if (matchedData != null) {
                    String fileName = matchedData.getFileName();
                    if (fileName == null || fileName.trim().isEmpty()) {
                        fileName = generatedName;
                    }
                    if (!fileName.toLowerCase().endsWith(".pdf")) {
                        fileName += ".pdf";
                    }

                    boolean fileNameValid = validateFileNameWithPdfValues(matchedData.getFileName(), reportNameSql, fieldValues);
                    if (!fileNameValid) {
                        String coreFromPdf = generateFileName(reportNameSql, fieldValues);
                        String normFile = normalizeFileName(matchedData.getFileName());
                        log.error("page " + (i + 1) + " filename mismatch, pdf=" + coreFromPdf + " fileName=" + normFile);
                        return false;
                    }

                    File outputFile = resolveOutputFile(refOutDir, fileName);
                    try (PDDocument singleDoc = new PDDocument()) {
                        PDPage sourcePage = doc.getPage(i);
                        PDPage newPage = singleDoc.importPage(sourcePage);
                        // Preserve inherited page boxes; importPage may fall back to default Letter size.
                        newPage.setMediaBox(sourcePage.getMediaBox());
                        newPage.setCropBox(sourcePage.getCropBox());
                        singleDoc.save(outputFile);
                    }
                    log.info("page " + (i + 1) + " -> " + outputFile.getName());
                    matched++;
                } else {
                    log.warn("page " + (i + 1) + " no match, generated=" + generatedName + " fields=" + fieldValues);
                    unmatched++;
                }
            }
        }

        String summary = "result: matched=" + matched + " unmatched=" + unmatched + " skipped=" + skipped;
        log.info(summary);

        if (matched == 0) {
            log.error("0 pages matched for " + pdfFile.getName());
            return false;
        }

        if (unmatched > 0) {
            log.error(unmatched + " page(s) unmatched for " + pdfFile.getName());
            return false;
        }

        return true;
    }

    // Merge the listed attachments into each generated PDF.
    private static boolean mergeAttachments(File refOutDir, File attachmentDir, String referenceNo, Instruction inst) {
        if (inst == null) {
            return true;
        }

        List<String> attachments = inst.getAttachmentNames();
        if (attachments.isEmpty()) {
            log.info("no attachments for " + referenceNo);
            return true;
        }

        if (!attachmentDir.exists() || !attachmentDir.isDirectory()) {
            log.warn("attachment dir not found: " + attachmentDir.getAbsolutePath());
            return false;
        }

        File[] outputPdfs = refOutDir.listFiles((dir, name) -> name.toLowerCase().endsWith(".pdf"));
        if (outputPdfs == null || outputPdfs.length == 0) {
            log.warn("no output PDFs to merge attachments into");
            return false;
        }

        Arrays.sort(outputPdfs, Comparator.comparing(File::getName));

        boolean allSucceeded = true;
        for (File outputPdf : outputPdfs) {
            if (!mergeAttachmentsIntoPdf(outputPdf, attachmentDir, referenceNo, attachments)) {
                allSucceeded = false;
            }
        }
        return allSucceeded;
    }

    // Merge one set of attachments into a single output PDF.
    private static boolean mergeAttachmentsIntoPdf(File outputPdf, File attachmentDir, String referenceNo, List<String> attachments) {
        try {
            int originalPages;
            try (PDDocument baseDoc = PDDocument.load(outputPdf)) {
                originalPages = baseDoc.getNumberOfPages();
            }

            PDFMergerUtility merger = new PDFMergerUtility();
            File tempFile = new File(outputPdf.getParent(), outputPdf.getName() + ".tmp");
            merger.setDestinationFileName(tempFile.getAbsolutePath());
            merger.addSource(outputPdf);

            boolean merged = false;
            for (String attachmentName : attachments) {
                File attachmentFile = new File(attachmentDir, referenceNo + File.separator + attachmentName);
                if (!attachmentFile.exists()) {
                    log.warn("attachment not found: " + attachmentFile.getAbsolutePath());
                    continue;
                }
                merger.addSource(attachmentFile);
                merged = true;
                log.info("merged attachment " + attachmentName + " into split PDF " + outputPdf.getName());
            }

            if (!merged) {
                log.warn("no attachments merged for " + outputPdf.getName());
                return true;
            }

            merger.mergeDocuments(MemoryUsageSetting.setupMainMemoryOnly());
            int mergedPages;
            try (PDDocument mergedDoc = PDDocument.load(tempFile)) {
                mergedPages = mergedDoc.getNumberOfPages();
            }
            Files.move(tempFile.toPath(), outputPdf.toPath(), StandardCopyOption.REPLACE_EXISTING);
            log.info("saved merged split PDF " + outputPdf.getName() + " (" + originalPages + " -> " + mergedPages + " pages)");
            return true;
        } catch (Exception e) {
            log.error("failed to merge attachments into split PDF " + outputPdf.getName(), e);
            File tempFile = new File(outputPdf.getParent(), outputPdf.getName() + ".tmp");
            if (tempFile.exists() && !tempFile.delete()) {
                log.warn("failed to delete temp file: " + tempFile.getAbsolutePath());
            }
            return false;
        }
    }

    // Copy generated PDFs to the extra output folder using a date/report/ref structure.
    private static void copyToExtraOutput(File refOutDir, File extraOutputDir, String reportName, String referenceNo) {
        if (extraOutputDir == null || !refOutDir.exists() || !refOutDir.isDirectory()) {
            return;
        }

        String dateFolder = new SimpleDateFormat("yyyyMMdd").format(new Date());
        File targetDir = new File(extraOutputDir, dateFolder + File.separator + reportName + File.separator + referenceNo);
        if (!targetDir.exists() && !targetDir.mkdirs()) {
            log.warn("failed to create extra output dir: " + targetDir.getAbsolutePath());
            return;
        }

        File[] outputPdfs = refOutDir.listFiles((dir, name) -> name.toLowerCase().endsWith(".pdf"));
        if (outputPdfs == null || outputPdfs.length == 0) {
            return;
        }

        for (File pdf : outputPdfs) {
            File targetFile = new File(targetDir, pdf.getName());
            try {
                Files.copy(pdf.toPath(), targetFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                log.info("copied to extra output: " + targetFile.getAbsolutePath());
            } catch (IOException e) {
                log.warn("failed to copy to extra output: " + pdf.getName(), e);
            }
        }
    }

    // Append an incremental suffix when the output filename already exists.
    private static File resolveOutputFile(File outDir, String fileName) {
        File outputFile = new File(outDir, fileName);
        if (!outputFile.exists()) {
            return outputFile;
        }

        String baseName;
        String ext;
        int lastDot = fileName.lastIndexOf('.');
        if (lastDot > 0) {
            baseName = fileName.substring(0, lastDot);
            ext = fileName.substring(lastDot);
        } else {
            baseName = fileName;
            ext = "";
        }

        int counter = 1;
        while (outputFile.exists()) {
            String newName = baseName + "_" + String.format("%03d", counter) + ext;
            outputFile = new File(outDir, newName);
            counter++;
        }
        return outputFile;
    }

    private static boolean isAllFieldsEmpty(Map<String, String> fieldValues) {
        if (fieldValues == null || fieldValues.isEmpty()) return true;
        for (String value : fieldValues.values()) {
            if (value != null && !value.isEmpty()) {
                return false;
            }
        }
        return true;
    }

    // Extract field names from ReportNameSQL trim() expressions.
    private static List<String> extractFieldsFromReportNameSql(String reportNameSql) {
        List<String> fields = new ArrayList<>();
        if (reportNameSql == null) return fields;
        Matcher m = TRIM_PATTERN.matcher(reportNameSql);
        while (m.find()) {
            String field = m.group(1);
            if (!fields.contains(field)) {
                fields.add(field);
            }
        }
        return fields;
    }

    // Convert a ReportNameSQL expression into an output filename.
    private static String generateFileName(String reportNameSql, Map<String, String> fieldValues) {
        if (reportNameSql == null) return "";

        String result = reportNameSql;

        Matcher trimMatcher = TRIM_PATTERN.matcher(result);
        StringBuffer sb = new StringBuffer();
        while (trimMatcher.find()) {
            String field = trimMatcher.group(1).toLowerCase();
            String value = fieldValues.getOrDefault(field, "");
            trimMatcher.appendReplacement(sb, Matcher.quoteReplacement(value));
        }
        trimMatcher.appendTail(sb);
        result = sb.toString();

        result = result.replace("''", "_").replace("'_'", "_");
        result = result.replace("'", "").replace("+", "");
        result = result.replace("(", "").replace(")", "");
        result = FN_SQL_SPACES.matcher(result).replaceAll("");

        result = FN_SQL_UNDERSCORES.matcher(result).replaceAll("_");
        result = FN_SQL_TRIM_EDGES.matcher(result).replaceAll("");

        return result;
    }

    // Compare the database filename core with the PDF-generated core.
    private static boolean validateFileNameWithPdfValues(String fileName, String reportNameSql,
                                                          Map<String, String> fieldValues) {
        if (fileName == null || fileName.isEmpty()) return true;
        String coreFromFile = extractCoreFromFileName(fileName);
        String generatedCore = generateFileName(reportNameSql, fieldValues);
        if (coreFromFile == null || coreFromFile.isEmpty()) return true;
        return coreFromFile.equalsIgnoreCase(generatedCore.replace("-", ""));
    }

    // Extract the account-fund core from a standard filename.
    private static String extractCoreFromFileName(String fileName) {
        if (fileName == null) return "";
        String base = fileName.trim();
        if (base.toLowerCase().endsWith(".pdf")) {
            base = base.substring(0, base.length() - 4);
        }
        Matcher m = CORE_PATTERN.matcher(base);
        if (m.matches()) {
            return m.group(3).toLowerCase().replace("-", "");
        }
        return base.toLowerCase().replace("-", "");
    }

    private static String normalizeFileName(String s) {
        if (s == null) return "";
        String result = s.trim();
        if (result.toLowerCase().endsWith(".pdf")) {
            result = result.substring(0, result.length() - 4);
        }
        return result.toLowerCase().replace("-", "");
    }

    // Check whether a configured field value exists in the PDF text, ignoring spaces and dashes.
    private static boolean isFieldMatch(String text, String flag, String value) {
        if (!"true".equalsIgnoreCase(flag)) {
            return true;
        }
        if (value == null || value.trim().isEmpty()) {
            return false;
        }
        String normalizedText = normalizeSearchText(text);
        String normalizedValue = normalizeSearchText(value);
        return normalizedText.contains(normalizedValue);
    }

    // Find the report data row whose configured fields all appear on the page.
    private static FormattedReportData findMatchByConfig(String text, List<FormattedReportData> formattedList, BulkUploadConfig config) {
        if (text == null || formattedList == null || formattedList.isEmpty() || config == null) {
            return null;
        }
        String normalizedText = normalizeSearchText(text);
        for (FormattedReportData fd : formattedList) {
            boolean portfolioMatch = isFieldMatch(text, config.getReportPortfoliono(), fd.getReportPortfoliono());
            boolean productMatch = isFieldMatch(text, config.getReportProduct(), fd.getReportProduct());
            boolean contractMatch = isFieldMatch(text, config.getReportContractno(), fd.getReportContractno());
            boolean clientMatch = isFieldMatch(text, config.getReportClientid(), fd.getReportClientid());
            boolean keyMatch = isFieldMatch(text, config.getReportKey(), fd.getReportKey());
            if (portfolioMatch && productMatch && contractMatch && clientMatch && keyMatch) {
                return fd;
            }
        }
        return null;
    }

    // Normalize text for loose matching by lowercasing and removing spaces and dashes.
    private static String normalizeSearchText(String s) {
        if (s == null) return "";
        return s.toLowerCase().replaceAll("\\s+", "").replace("-", "");
    }

    // Build a field map from ReportData, supporting direct and legacy aliases.
    private static Map<String, String> buildFieldValuesFromReportData(ReportData rd, List<String> fields) {
        Map<String, String> values = new HashMap<>();
        if (rd == null || fields == null) return values;
        for (String field : fields) {
            String lowerField = field.toLowerCase();
            String value = getReportDataValue(rd, lowerField);
            values.put(lowerField, value != null ? value : "");
        }
        return values;
    }

    // Resolve a ReportData property by its field alias.
    private static String getReportDataValue(ReportData rd, String field) {
        switch (field) {
            case "report_portfoliono":
                return rd.getReportPortfoliono();
            case "report_product":
                return rd.getReportProduct();
            case "report_contractno":
                return rd.getReportContractno();
            case "report_clientid":
                return rd.getReportClientid();
            case "report_key":
                return rd.getReportKey();
            case "portnum":
            case "portno":
            case "noteaccountno":
            case "portfoliono":
                return coalesce(rd.getReportPortfoliono(), rd.getReportClientid());
            case "clientnumber":
                return coalesce(rd.getReportPortfoliono(), rd.getReportClientid());
            case "fundcode":
            case "productcode":
            case "fund":
            case "outfundcode":
                return rd.getReportProduct();
            case "contractno":
            case "contractnumber":
                return rd.getReportContractno();
            case "clientid":
                return rd.getReportClientid();
            case "reportkey":
                return rd.getReportKey();
            default:
                return "";
        }
    }

    // Locate the referenceNo.pdf file in the bulk upload folder.
    private static File findPdfFile(File bulkDir, String referenceNo) {
        File pdfFile = new File(bulkDir, referenceNo + ".pdf");
        if (pdfFile.isFile()) {
            return pdfFile;
        }
        return null;
    }

    // Return the first non-empty value.
    private static String coalesce(String... values) {
        for (String v : values) {
            if (v != null && !v.isEmpty()) {
                return v;
            }
        }
        return null;
    }
}
