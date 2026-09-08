package com.mrc.model;

import lombok.Data;

/**
 * Entity for BPSS.dbo.TB_eDoc_ReportTemplate
 */
@Data
public class ReportTemplate {
    private String templateId;
    private String bossStatementType;
    private String reportName;
    private String reportDescription;
    private String permissionCode;
    private String reportPath;
    private String tbDb;
    private String tableName;
    private String spDb;
    private String spName;
    private String spParameter;
    private String schedule;
    private String time;
    private String reportNameSql;
    private String portfolioField;
    private String productField;
    private String contractNoField;
    private String clientIdField;
    private String reportKeyField;
    private String dateParameter;
    private String tableNameManualHandle;
    private String allowAttachment;
}
