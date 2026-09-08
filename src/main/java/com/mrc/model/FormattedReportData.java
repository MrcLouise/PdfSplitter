package com.mrc.model;

import lombok.Data;

import java.util.Date;

/**
 * ReportData values after applying TB_eDoc_BulkUpload_Config SQL formats.
 */
@Data
public class FormattedReportData {
    private Integer seqNo;
    private String templateId;
    private String referenceNo;
    private String bossStatementType;
    private Date reportDate;
    private String reportPortfoliono;
    private String reportProduct;
    private String reportContractno;
    private String reportClientid;
    private String reportKey;
    private String reportName;
    private String fileName;
    private String eflag;
    private Boolean deleted;
}
