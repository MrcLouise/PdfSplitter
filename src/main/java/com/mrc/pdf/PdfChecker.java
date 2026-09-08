package com.mrc.pdf;

import com.mrc.config.AppConfig;
import com.mrc.db.DatabaseManager;
import com.mrc.model.PdfCheckInstruction;
import com.mrc.model.ReportTemplate;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.Date;
import java.util.List;

/**
 * PdfChecker entry point: scans report PDF folders and verifies each file
 * contains the account number extracted from its file name.
 */
public class PdfChecker {

    private static final Logger log = LoggerFactory.getLogger(PdfChecker.class);

    // Characters removed when normalising text/address for comparison
    private static final String ADDRESS_NOISE = " ,.-/()\\'\"";
    // External error log path: failures are appended here (created if missing)
    private static final String ERR_LOG_PATH = "E:\\CDDownload\\ErrLog\\JOB_UT_DAY_Combine";
    //private static final String ERR_LOG_PATH = "C:\\Users\\95301\\Desktop\\CDDownload\\ErrLog\\JOB_UT_DAY_Combine";

    // Load config, validate directories, and run account number checks for all confirmed instructions.
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
            log.error("usage: pdfchecker <baseDir> [logDir]");
            System.exit(1);
        }

        String baseFolder = args[0].replace("\"", "").trim();
        String logFolder = args.length >= 2 ? args[1].replace("\"", "").trim() : baseFolder;

        File baseDir = new File(baseFolder);
        if (!baseDir.exists() || !baseDir.isDirectory()) {
            log.error("base dir not found: " + baseFolder);
            System.exit(1);
        }

        File logDir = new File(logFolder);
        if (!logDir.exists() && !logDir.mkdirs()) {
            log.error("cannot create log dir: " + logFolder);
            System.exit(1);
        }

        DailyLogManager logManager = new DailyLogManager(logDir);
        logManager.rotateIfNeeded();

        log.info("pdfchecker started, baseDir=" + baseDir.getAbsolutePath()
                + ", log=" + logManager.getLogFile().getAbsolutePath());

        boolean hasFailure = false;
        int total = 0;
        int success = 0;

        try (DatabaseManager db = new DatabaseManager()) {
            log.info("rotating pdfcheck daily/history tables");
            db.rotatePdfCheckDaily();

            List<PdfCheckInstruction> instructions = db.loadConfirmedInstructions();
            total = instructions.size();
            log.info("found " + total + " confirmed instructions");

            for (PdfCheckInstruction inst : instructions) {
                int dailyId = db.insertPdfCheckDaily(inst);
                inst.setDailyId(dailyId);
                log.info("inserted daily record id=" + dailyId + " for " + keyOf(inst));
            }

            for (PdfCheckInstruction inst : instructions) {
                Date startTime = new Date();
                CheckResult result = checkInstruction(db, baseDir, inst);
                Date endTime = new Date();

                String status;
                String errorDetail = result.getErrorDetail();
                if (result.isOk()) {
                    status = "SUCCESS";
                    success++;
                    log.info("SUCCESS " + keyOf(inst));
                } else if (result.isSkip()) {
                    status = "SKIPPED";
                    log.info("SKIPPED " + keyOf(inst) + ": " + errorDetail);
                } else {
                    status = "FAILED";
                    hasFailure = true;
                    log.error("FAILED " + keyOf(inst) + ": " + errorDetail);
                    try {
                        logManager.writeLine("ERROR " + keyOf(inst) + " - " + errorDetail);
                    } catch (IOException e) {
                        log.error("failed to write error log", e);
                    }
                    appendErrLog("ERROR " + keyOf(inst) + " - " + errorDetail);
                }
                db.updatePdfCheckDaily(inst.getDailyId(), status, errorDetail, startTime, endTime);
            }
        } catch (Exception e) {
            log.error("pdfchecker fatal error", e);
            try {
                logManager.writeLine("ERROR fatal: " + e.getMessage());
            } catch (IOException io) {
                log.error("failed to write fatal error log", io);
            }
            appendErrLog("ERROR fatal: " + e.getMessage());
            System.exit(1);
        }

        log.info("pdfchecker finished, success=" + success + "/" + total);
        if (hasFailure) {
            System.exit(1);
        }
    }

    // Verify every PDF in the instruction's report folder contains its account number.
    // Skips instructions where recordCountAfterSubmit is null or 0.
    private static CheckResult checkInstruction(DatabaseManager db, File baseDir, PdfCheckInstruction inst) {
        String templateId = inst.getTemplateId();
        String referenceNo = inst.getReferenceNo();
        Integer recordCountAfterSubmit = inst.getRecordCountAfterSubmit();

        if (recordCountAfterSubmit == null || recordCountAfterSubmit == 0) {
            String reason = "recordCountAfterSubmit is " + recordCountAfterSubmit;
            log.info("skip " + keyOf(inst) + ": " + reason);
            return CheckResult.skip(reason);
        }

        ReportTemplate template;
        try {
            template = db.loadReportTemplate(templateId);
        } catch (SQLException e) {
            return CheckResult.fail("failed to load report template for " + templateId + ": " + e.getMessage());
        }
        if (template == null) {
            return CheckResult.fail("report template not found: " + templateId);
        }

        String reportName = template.getReportName();
        if (reportName == null || reportName.trim().isEmpty()) {
            reportName = templateId;
        }
        reportName = reportName.replaceAll("[^a-zA-Z0-9\\-_.]", "_");

        String folderName = (referenceNo != null && !referenceNo.trim().isEmpty()) ? referenceNo.trim() : templateId;
        boolean hasReference = referenceNo != null && !referenceNo.trim().isEmpty();

        // Prefixed layout only applies with a real referenceNo; when referenceNo is empty,
        // folderName IS the templateId and prefixing would produce names that never exist
        // on disk, like "Template1_Template1".
        File reportDir = resolveReportDir(baseDir, reportName, folderName, hasReference ? templateId : null);
        if (reportDir == null) {
            File plainDir = new File(baseDir, reportName + File.separator + folderName);
            if (!hasReference) {
                return CheckResult.fail("report folder not found: " + plainDir.getAbsolutePath());
            }
            File prefixedDir = new File(baseDir, reportName + File.separator + prefixedFolderName(templateId, folderName));
            return CheckResult.fail("report folder not found: " + plainDir.getAbsolutePath()
                    + " or " + prefixedDir.getAbsolutePath());
        }

        File[] pdfFiles = reportDir.listFiles((dir, name) -> name.toLowerCase().endsWith(".pdf"));
        if (pdfFiles == null || pdfFiles.length == 0) {
            return CheckResult.fail("no PDF files found in report folder: " + reportDir.getAbsolutePath());
        }

        Arrays.sort(pdfFiles, Comparator.comparing(File::getName));

        List<String> errors = new ArrayList<>();

        for (File pdfFile : pdfFiles) {
            String accountNo = extractAccountNoFromFileName(pdfFile.getName());
            if (accountNo == null || accountNo.isEmpty()) {
                errors.add(pdfFile.getName() + ": cannot extract account number from file name");
                continue;
            }

            String pdfText;
            try {
                pdfText = extractPdfText(pdfFile);
            } catch (Exception e) {
                errors.add(pdfFile.getName() + ": cannot read PDF text - " + e.getMessage());
                continue;
            }

            if (!containsNormalized(pdfText, accountNo)) {
                errors.add(pdfFile.getName() + ": account number " + accountNo + " not found in PDF content");
            }
        }

        if (errors.isEmpty()) {
            return CheckResult.ok();
        }
        return CheckResult.fail(String.join("; ", errors));
    }

    // Resolve the report folder: prefer "<reportName>/<folderName>"; if missing, fall back to
    // "<reportName>/Template<templateId>_<folderName>" used by templates that share one reportName
    // (e.g. CorporateActionGeneric\Template31_CA20260730001). Pass templateId = null to disable
    // the prefixed fallback (no real referenceNo). Returns null when nothing matches.
    static File resolveReportDir(File baseDir, String reportName, String folderName, String templateId) {
        File plainDir = new File(baseDir, reportName + File.separator + folderName);
        if (plainDir.isDirectory()) {
            return plainDir;
        }
        if (templateId == null) {
            return null;
        }
        File prefixedDir = new File(baseDir, reportName + File.separator + prefixedFolderName(templateId, folderName));
        if (prefixedDir.isDirectory()) {
            return prefixedDir;
        }
        return null;
    }

    // "Template31"-style folder prefix: prepend "Template" to the templateId, unless the
    // templateId already starts with it (test data uses ids like "Template31").
    private static String prefixedFolderName(String templateId, String folderName) {
        String prefix = templateId != null && templateId.toLowerCase().startsWith("template")
                ? templateId
                : "Template" + templateId;
        return prefix + "_" + folderName;
    }

    // Extracts the account number from a file name formatted as:
    // <date>_<type>_<accountNo>_<seq>.pdf
    // e.g. "20260807_33_NA0035981001_000923.pdf" -> "NA0035981001"
    private static String extractAccountNoFromFileName(String fileName) {
        if (fileName == null) {
            return null;
        }
        String base = fileName;
        if (base.toLowerCase().endsWith(".pdf")) {
            base = base.substring(0, base.length() - 4);
        }
        String[] parts = base.split("_");
        if (parts.length < 4) {
            return null;
        }
        return parts[2];
    }

    private static String extractPdfText(File pdfFile) throws IOException {
        try (PDDocument doc = PDDocument.load(pdfFile)) {
            PDFTextStripper stripper = new PDFTextStripper();
            return stripper.getText(doc);
        }
    }

    private static boolean containsNormalized(String text, String value) {
        if (text == null || value == null) {
            return false;
        }
        return normalize(text).contains(normalize(value));
    }

    private static String normalize(String s) {
        if (s == null) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (char c : s.toLowerCase().toCharArray()) {
            // Remove address noise and all whitespace (including newlines/tabs)
            // so that values split across lines in the PDF still match.
            if (ADDRESS_NOISE.indexOf(c) < 0 && !Character.isWhitespace(c)) {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    private static String keyOf(PdfCheckInstruction inst) {
        return inst.getTemplateId() + "/" + inst.getReferenceNo();
    }

    // Append a timestamped error line to the external errlog file.
    // Creates the file (and parent directories) if they do not exist.
    private static void appendErrLog(String message) {
        if (message == null || message.trim().isEmpty()) {
            return;
        }

        File errLog = new File(ERR_LOG_PATH);
        File parent = errLog.getParentFile();
        if (parent != null && !parent.exists() && !parent.mkdirs()) {
            log.warn("failed to create errlog dir: " + parent.getAbsolutePath());
            return;
        }

        String timestamp = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
        String line = timestamp + " " + message + System.lineSeparator();
        try {
            Files.write(errLog.toPath(), line.getBytes(StandardCharsets.UTF_8),
                    StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException e) {
            log.warn("failed to write errlog: " + e.getMessage());
        }
    }

    private static class CheckResult {
        private enum Type { OK, FAIL, SKIP }

        private final Type type;
        private final String errorDetail;

        private CheckResult(Type type, String errorDetail) {
            this.type = type;
            this.errorDetail = errorDetail;
        }

        static CheckResult ok() {
            return new CheckResult(Type.OK, null);
        }

        static CheckResult fail(String errorDetail) {
            return new CheckResult(Type.FAIL, errorDetail);
        }

        static CheckResult skip(String reason) {
            return new CheckResult(Type.SKIP, reason);
        }

        boolean isOk() {
            return type == Type.OK;
        }

        boolean isFail() {
            return type == Type.FAIL;
        }

        boolean isSkip() {
            return type == Type.SKIP;
        }

        String getErrorDetail() {
            return errorDetail;
        }
    }
}
