package com.mrc.model;

import lombok.Data;

import java.util.Date;

/**
 * Lightweight instruction record for pdfchecker (status = CONFIRMED).
 */
@Data
public class PdfCheckInstruction {
    private int dailyId;
    private String templateId;
    private String referenceNo;
    private String reportTitle;
    private Date reportDate;
    private Integer recordCount;
    private Integer recordCountAfterSubmit;
    private String status;
}
