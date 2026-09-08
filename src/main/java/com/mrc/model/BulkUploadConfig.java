package com.mrc.model;

import lombok.Data;

/**
 * Entity for BPSS.dbo.TB_eDoc_BulkUpload_Config
 */
@Data
public class BulkUploadConfig {
    private Integer id;
    private String templateId;
    private String reportPortfoliono;
    private String reportPortfolionoFormat;
    private String reportProduct;
    private String reportProductFormat;
    private String reportContractno;
    private String reportClientid;
    private String reportKey;
    private Boolean active;
    private Boolean deleted;
}
