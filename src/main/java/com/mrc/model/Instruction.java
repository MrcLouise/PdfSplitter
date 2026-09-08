package com.mrc.model;

import lombok.Data;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * BPSS.dbo.TB_eDoc_Instr 实体类
 */
@Data
public class Instruction {
    private String templateId;
    private String referenceNo;
    private String reportTitle;
    private Date reportDate;
    private Integer recordCount;
    private Integer recordCountAfterSubmit;
    private String status;
    private Date createDate;
    private String createUser;
    private Date updateDate;
    private String updateUser;
    private Date utDigitalStartTime;
    private Date utDigitalEndTime;

    private String singleUpload;

    public boolean isSingleUpload() {
        return singleUpload != null && singleUpload.equalsIgnoreCase("Y");
    }

    public List<String> getAttachmentNames() {
        List<String> names = new ArrayList<>();
        addIfNotEmpty(names, attachment1);
        addIfNotEmpty(names, attachment2);
        addIfNotEmpty(names, attachment3);
        addIfNotEmpty(names, attachment4);
        addIfNotEmpty(names, attachment5);
        addIfNotEmpty(names, attachment6);
        addIfNotEmpty(names, attachment7);
        addIfNotEmpty(names, attachment8);
        addIfNotEmpty(names, attachment9);
        addIfNotEmpty(names, attachment10);
        addIfNotEmpty(names, attachment11);
        addIfNotEmpty(names, attachment12);
        addIfNotEmpty(names, attachment13);
        addIfNotEmpty(names, attachment14);
        addIfNotEmpty(names, attachment15);
        addIfNotEmpty(names, attachment16);
        addIfNotEmpty(names, attachment17);
        addIfNotEmpty(names, attachment18);
        addIfNotEmpty(names, attachment19);
        addIfNotEmpty(names, attachment20);
        return names;
    }

    private void addIfNotEmpty(List<String> list, String value) {
        if (value != null && !value.trim().isEmpty()) {
            list.add(value.trim());
        }
    }

    private String attachment1;
    private String attachment2;
    private String attachment3;
    private String attachment4;
    private String attachment5;
    private String attachment6;
    private String attachment7;
    private String attachment8;
    private String attachment9;
    private String attachment10;
    private String attachment11;
    private String attachment12;
    private String attachment13;
    private String attachment14;
    private String attachment15;
    private String attachment16;
    private String attachment17;
    private String attachment18;
    private String attachment19;
    private String attachment20;
}
