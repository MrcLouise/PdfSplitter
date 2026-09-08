package com.mrc.db;

import com.mrc.config.AppConfig;
import com.mrc.model.BulkUploadConfig;
import com.mrc.model.FormattedReportData;
import com.mrc.model.Instruction;
import com.mrc.model.PdfCheckInstruction;
import com.mrc.model.ReportData;
import com.mrc.model.ReportTemplate;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DatabaseManager implements AutoCloseable {

    private static final Logger log = LoggerFactory.getLogger(DatabaseManager.class);
    private final HikariDataSource dataSource;

    public DatabaseManager() throws Exception {
        AppConfig config = new AppConfig();

        String connString = config.getConnectionString("BPSS");
        if (connString == null || connString.trim().isEmpty()) {
            throw new IllegalStateException("BPSS connection string not found in CONNECTION.XML");
        }
        String jdbcUrl = toJdbcUrl(connString);

        HikariConfig hikariConfig = new HikariConfig();
        hikariConfig.setJdbcUrl(jdbcUrl);
        hikariConfig.setDriverClassName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        hikariConfig.setMaximumPoolSize(5);
        hikariConfig.setMinimumIdle(1);
        hikariConfig.setConnectionTimeout(30000);
        hikariConfig.setIdleTimeout(600000);
        hikariConfig.setMaxLifetime(1800000);
        hikariConfig.setPoolName("PdfSplitterPool");

        this.dataSource = new HikariDataSource(hikariConfig);
    }

    private Connection getConnection() throws SQLException {
        return dataSource.getConnection();
    }

    /**
     * Convert a .NET style SQL Server connection string to a JDBC URL.
     */
    private static String toJdbcUrl(String connectionString) {
        if (connectionString == null) {
            return null;
        }
        String trimmed = connectionString.trim();
        if (trimmed.toLowerCase().startsWith("jdbc:")) {
            return trimmed;
        }

        StringBuilder url = new StringBuilder("jdbc:sqlserver://");
        String[] pairs = trimmed.split(";");
        boolean serverAppended = false;

        for (String pair : pairs) {
            int idx = pair.indexOf('=');
            if (idx <= 0) {
                continue;
            }
            String key = pair.substring(0, idx).trim();
            String value = pair.substring(idx + 1).trim();
            if (value.isEmpty()) {
                continue;
            }

            switch (key.toLowerCase()) {
                case "data source":
                    url.append(value);
                    serverAppended = true;
                    break;
                case "initial catalog":
                    url.append(";databaseName=").append(value);
                    break;
                case "user id":
                case "userid":
                case "user":
                    url.append(";user=").append(value);
                    break;
                case "password":
                    url.append(";password=").append(value);
                    break;
                case "connection timeout":
                    url.append(";loginTimeout=").append(value);
                    break;
                case "encrypt":
                    url.append(";encrypt=").append(value);
                    break;
                case "trustservercertificate":
                    url.append(";trustServerCertificate=").append(value);
                    break;
                default:
                    // Ignore unknown keys
                    break;
            }
        }

        if (!serverAppended) {
            throw new IllegalArgumentException("Data Source not found in connection string: " + connectionString);
        }
        return url.toString();
    }

    public ReportTemplate loadReportTemplate(String templateId) throws SQLException {
        String sql = "{call Sp_eDoc_LoadReportTemplate(?)}";
        try (Connection conn = getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, templateId);
            try (ResultSet rs = cs.executeQuery()) {
                if (rs.next()) {
                    return mapReportTemplate(rs);
                }
            }
        }
        return null;
    }

    public List<Instruction> loadInstructionsByStatus(String status) throws SQLException {
        List<Instruction> list = new ArrayList<>();
        String sql = "{call Sp_eDoc_LoadInstructions(?)}";
        try (Connection conn = getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, status);
            try (ResultSet rs = cs.executeQuery()) {
                while (rs.next()) {
                    list.add(mapInstruction(rs));
                }
            }
        }
        return list;
    }

    public List<ReportData> loadReportDataByTemplateAndRef(String templateId, String referenceNo) throws SQLException {
        List<ReportData> list = new ArrayList<>();
        String sql = "{call Sp_eDoc_LoadReportData(?, ?)}";
        try (Connection conn = getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, templateId);
            cs.setString(2, referenceNo);
            try (ResultSet rs = cs.executeQuery()) {
                while (rs.next()) {
                    list.add(mapReportData(rs));
                }
            }
        }
        return list;
    }

    public BulkUploadConfig loadBulkUploadConfig(String templateId) throws SQLException {
        String sql = "{call Sp_eDoc_LoadBulkUploadConfig(?)}";
        try (Connection conn = getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, templateId);
            try (ResultSet rs = cs.executeQuery()) {
                if (rs.next()) {
                    BulkUploadConfig config = mapBulkUploadConfig(rs);
                    log.debug("loadBulkUploadConfig templateId=" + templateId
                            + " reportPortfoliono=" + config.getReportPortfoliono()
                            + " reportProduct=" + config.getReportProduct()
                            + " reportContractno=" + config.getReportContractno()
                            + " reportClientid=" + config.getReportClientid()
                            + " reportKey=" + config.getReportKey());
                    return config;
                }
            }
        }
        return null;
    }

    public List<FormattedReportData> loadFormattedReportData(BulkUploadConfig config, String templateId, String referenceNo) throws SQLException {
        List<FormattedReportData> list = new ArrayList<>();
        if (config == null) {
            return list;
        }

        StringBuilder select = new StringBuilder();
        select.append("SELECT SeqNo, templateId, ReferenceNo, boss_statement_type, Report_Date, ");
        select.append(formatColumn(config.getReportPortfoliono(), config.getReportPortfolionoFormat(), "REPORT_PORTFOLIONO", "pdfPortfolio")).append(", ");
        select.append(formatColumn(config.getReportProduct(), config.getReportProductFormat(), "REPORT_PRODUCT", "pdfProduct")).append(", ");
        select.append(formatColumn(config.getReportContractno(), null, "REPORT_CONTRACTNO", "pdfContractNo")).append(", ");
        select.append(formatColumn(config.getReportClientid(), null, "REPORT_CLIENTID", "pdfClientId")).append(", ");
        select.append(formatColumn(config.getReportKey(), null, "REPORT_KEY", "pdfReportKey")).append(", ");
        select.append("ReportName, FileName, EFlag, Deleted ");
        select.append("FROM TB_eDoc_ReportData ");
        select.append("WHERE templateId = ? AND ReferenceNo = ? AND (Deleted = 0 OR Deleted IS NULL)");

        String sql = select.toString();
        try (Connection conn = getConnection();
             java.sql.PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, templateId);
            ps.setString(2, referenceNo);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapFormattedReportData(rs));
                }
            }
        }
        return list;
    }

    private static String formatColumn(String flag, String formatExpr, String sourceColumn, String alias) {
        if (!"true".equalsIgnoreCase(flag)) {
            return sourceColumn + " AS " + alias;
        }
        if (formatExpr == null || formatExpr.trim().isEmpty()) {
            return sourceColumn + " AS " + alias;
        }
        return "(" + formatExpr + ") AS " + alias;
    }

    public void updateInstructionStatus(String templateId, String referenceNo, String status, String updateUser, Date startTime, Date endTime) throws SQLException {
        String sql = "{call Sp_eDoc_UpdateStatus(?, ?, ?, ?, ?, ?)}";
        try (Connection conn = getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, templateId);
            cs.setString(2, referenceNo);
            cs.setString(3, status);
            cs.setString(4, updateUser != null ? updateUser : "SYSTEM");
            cs.setTimestamp(5, startTime != null ? new Timestamp(startTime.getTime()) : null);
            cs.setTimestamp(6, endTime != null ? new Timestamp(endTime.getTime()) : null);
            cs.executeUpdate();
        }
    }

    private static ReportTemplate mapReportTemplate(ResultSet rs) throws SQLException {
        ReportTemplate t = new ReportTemplate();
        t.setTemplateId(rs.getString("templateId"));
        t.setBossStatementType(rs.getString("boss_statement_type"));
        t.setReportName(rs.getString("reportName"));
        t.setReportDescription(rs.getString("reportDescription"));
        t.setPermissionCode(rs.getString("Permission_Code"));
        t.setReportPath(rs.getString("reportPath"));
        t.setTbDb(rs.getString("TB_DB"));
        t.setTableName(rs.getString("tableName"));
        t.setSpDb(rs.getString("SP_DB"));
        t.setSpName(rs.getString("SPName"));
        t.setSpParameter(rs.getString("SPParmater"));
        t.setSchedule(rs.getString("Schedule"));
        t.setTime(rs.getString("Time"));
        t.setReportNameSql(rs.getString("ReportNameSQL"));
        t.setPortfolioField(rs.getString("PortfolioField"));
        t.setProductField(rs.getString("ProductField"));
        t.setContractNoField(rs.getString("ContractNoField"));
        t.setClientIdField(rs.getString("ClientIDField"));
        t.setReportKeyField(rs.getString("ReportKeyField"));
        t.setDateParameter(rs.getString("DateParameter"));
        t.setTableNameManualHandle(rs.getString("tableName_ManualHandle"));
        t.setAllowAttachment(rs.getString("AllowAttachment"));
        return t;
    }

    private static Instruction mapInstruction(ResultSet rs) throws SQLException {
        Instruction inst = new Instruction();
        inst.setTemplateId(rs.getString("templateId"));
        inst.setReferenceNo(rs.getString("ReferenceNo"));
        inst.setStatus(rs.getString("Status"));
        inst.setReportTitle(rs.getString("Report_Title"));
        inst.setReportDate(rs.getTimestamp("Report_Date"));
        inst.setRecordCount(getNullableInt(rs, "RecordCount"));
        inst.setRecordCountAfterSubmit(getNullableInt(rs, "RecordCountAfterSubmit"));
        inst.setCreateDate(rs.getTimestamp("createDate"));
        inst.setCreateUser(rs.getString("createUser"));
        inst.setUpdateDate(rs.getTimestamp("updateDate"));
        inst.setUpdateUser(rs.getString("updateUser"));
        inst.setUtDigitalStartTime(rs.getTimestamp("UTDigitalStartTime"));
        inst.setUtDigitalEndTime(rs.getTimestamp("UTDigitalEndTime"));
        inst.setSingleUpload(rs.getString("SingleUpload"));
        inst.setAttachment1(rs.getString("Attachment1"));
        inst.setAttachment2(rs.getString("Attachment2"));
        inst.setAttachment3(rs.getString("Attachment3"));
        inst.setAttachment4(rs.getString("Attachment4"));
        inst.setAttachment5(rs.getString("Attachment5"));
        inst.setAttachment6(rs.getString("Attachment6"));
        inst.setAttachment7(rs.getString("Attachment7"));
        inst.setAttachment8(rs.getString("Attachment8"));
        inst.setAttachment9(rs.getString("Attachment9"));
        inst.setAttachment10(rs.getString("Attachment10"));
        inst.setAttachment11(rs.getString("Attachment11"));
        inst.setAttachment12(rs.getString("Attachment12"));
        inst.setAttachment13(rs.getString("Attachment13"));
        inst.setAttachment14(rs.getString("Attachment14"));
        inst.setAttachment15(rs.getString("Attachment15"));
        inst.setAttachment16(rs.getString("Attachment16"));
        inst.setAttachment17(rs.getString("Attachment17"));
        inst.setAttachment18(rs.getString("Attachment18"));
        inst.setAttachment19(rs.getString("Attachment19"));
        inst.setAttachment20(rs.getString("Attachment20"));
        return inst;
    }

    private static ReportData mapReportData(ResultSet rs) throws SQLException {
        ReportData rd = new ReportData();
        rd.setSeqNo(rs.getInt("SeqNo"));
        rd.setTemplateId(rs.getString("templateId"));
        rd.setReferenceNo(rs.getString("ReferenceNo"));
        rd.setBossStatementType(rs.getString("boss_statement_type"));
        rd.setReportDate(rs.getTimestamp("Report_Date"));
        rd.setReportPortfoliono(rs.getString("REPORT_PORTFOLIONO"));
        rd.setReportProduct(rs.getString("REPORT_PRODUCT"));
        rd.setReportContractno(rs.getString("REPORT_CONTRACTNO"));
        rd.setReportClientid(rs.getString("REPORT_CLIENTID"));
        rd.setReportKey(rs.getString("REPORT_KEY"));
        rd.setReportName(rs.getString("ReportName"));
        rd.setFileName(rs.getString("FileName"));
        rd.setEflag(rs.getString("EFlag"));
        rd.setDeleted(getNullableBoolean(rs, "Deleted"));
        return rd;
    }

    private static BulkUploadConfig mapBulkUploadConfig(ResultSet rs) throws SQLException {
        BulkUploadConfig c = new BulkUploadConfig();
        c.setId(rs.getInt("id"));
        c.setTemplateId(rs.getString("templateId"));
        c.setReportPortfoliono(rs.getString("reportPortfoliono"));
        c.setReportPortfolionoFormat(rs.getString("reportPortfolionoFormat"));
        c.setReportProduct(rs.getString("reportProduct"));
        c.setReportProductFormat(rs.getString("reportProductFormat"));
        c.setReportContractno(rs.getString("reportContractno"));
        c.setReportClientid(rs.getString("reportClientid"));
        c.setReportKey(rs.getString("reportKey"));
        c.setActive(getNullableBoolean(rs, "active"));
        c.setDeleted(getNullableBoolean(rs, "deleted"));
        return c;
    }

    private static FormattedReportData mapFormattedReportData(ResultSet rs) throws SQLException {
        FormattedReportData fd = new FormattedReportData();
        fd.setSeqNo(rs.getInt("SeqNo"));
        fd.setTemplateId(rs.getString("templateId"));
        fd.setReferenceNo(rs.getString("ReferenceNo"));
        fd.setBossStatementType(rs.getString("boss_statement_type"));
        fd.setReportDate(rs.getTimestamp("Report_Date"));
        fd.setReportPortfoliono(rs.getString("pdfPortfolio"));
        fd.setReportProduct(rs.getString("pdfProduct"));
        fd.setReportContractno(rs.getString("pdfContractNo"));
        fd.setReportClientid(rs.getString("pdfClientId"));
        fd.setReportKey(rs.getString("pdfReportKey"));
        fd.setReportName(rs.getString("ReportName"));
        fd.setFileName(rs.getString("FileName"));
        fd.setEflag(rs.getString("EFlag"));
        fd.setDeleted(getNullableBoolean(rs, "Deleted"));
        return fd;
    }

    private static Integer getNullableInt(ResultSet rs, String column) throws SQLException {
        int value = rs.getInt(column);
        return rs.wasNull() ? null : value;
    }

    private static boolean getNullableBoolean(ResultSet rs, String column) throws SQLException {
        boolean value = rs.getBoolean(column);
        return !rs.wasNull() && value;
    }

    // ==================== PdfChecker support ====================

    public void rotatePdfCheckDaily() throws SQLException {
        String sql = "{call Sp_eDoc_PdfCheck_RotateDaily}";
        try (Connection conn = getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.executeUpdate();
        }
    }

    public List<PdfCheckInstruction> loadConfirmedInstructions() throws SQLException {
        List<PdfCheckInstruction> list = new ArrayList<>();
        String sql = "{call Sp_eDoc_PdfCheck_LoadConfirmed}";
        try (Connection conn = getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            try (ResultSet rs = cs.executeQuery()) {
                while (rs.next()) {
                    list.add(mapPdfCheckInstruction(rs));
                }
            }
        }
        return list;
    }

    public int insertPdfCheckDaily(PdfCheckInstruction inst) throws SQLException {
        String sql = "{call Sp_eDoc_PdfCheck_InsertDaily(?, ?, ?, ?, ?)}";
        try (Connection conn = getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setString(1, inst.getTemplateId());
            // ReferenceNo may be empty/null in TB_eDoc_Instr; keep it as empty string for the daily record.
            // The report folder naming convention uses templateId when referenceNo is empty, handled in PdfChecker.
            cs.setString(2, inst.getReferenceNo() != null ? inst.getReferenceNo() : "");
            cs.setString(3, inst.getReportTitle());
            cs.setTimestamp(4, inst.getReportDate() != null ? new Timestamp(inst.getReportDate().getTime()) : null);
            cs.setObject(5, inst.getRecordCountAfterSubmit(), java.sql.Types.INTEGER);
            try (ResultSet rs = cs.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("id");
                }
            }
        }
        return -1;
    }

    public void updatePdfCheckDaily(int id, String status, String errorDetail, Date startTime, Date endTime) throws SQLException {
        String sql = "{call Sp_eDoc_PdfCheck_UpdateDaily(?, ?, ?, ?, ?)}";
        try (Connection conn = getConnection();
             CallableStatement cs = conn.prepareCall(sql)) {
            cs.setInt(1, id);
            cs.setString(2, status);
            cs.setString(3, errorDetail);
            cs.setTimestamp(4, startTime != null ? new Timestamp(startTime.getTime()) : null);
            cs.setTimestamp(5, endTime != null ? new Timestamp(endTime.getTime()) : null);
            cs.executeUpdate();
        }
    }

    private static PdfCheckInstruction mapPdfCheckInstruction(ResultSet rs) throws SQLException {
        PdfCheckInstruction inst = new PdfCheckInstruction();
        inst.setTemplateId(rs.getString("templateId"));
        inst.setReferenceNo(rs.getString("ReferenceNo"));
        inst.setReportTitle(rs.getString("Report_Title"));
        inst.setReportDate(rs.getTimestamp("Report_Date"));
        inst.setRecordCount(getNullableInt(rs, "RecordCount"));
        inst.setRecordCountAfterSubmit(getNullableInt(rs, "RecordCountAfterSubmit"));
        inst.setStatus(rs.getString("Status"));
        return inst;
    }

    @Override
    public void close() {
        if (dataSource != null && !dataSource.isClosed()) {
            dataSource.close();
        }
    }
}
