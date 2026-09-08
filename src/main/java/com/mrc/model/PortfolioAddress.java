package com.mrc.model;

import lombok.Data;

/**
 * Portfolio address loaded from HITRUST..DSBProfAddVW for pdfchecker.
 */
@Data
public class PortfolioAddress {
    private int seqNo;
    private String portfolioNo;
    private String portfolioKey;
    private String portName;
    private String portAdd1;
    private String portAdd2;
    private String portAdd3;
    private String portAdd4;
}
