package com.mrc.model;

import lombok.Data;

import java.util.Date;

/**
 * Entity for BPSS.dbo.TB_eDoc_ReportData
 */
@Data
public class ReportData {
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
