USE [BPSS]
GO

-- ============================================================
-- PdfChecker Template31 測試資料
-- 情境：templateId Template31/Template32/Template33 共用
--       reportName = CorporateActionGeneric，
--       磁碟目錄為 Template<数字>_<ReferenceNo> 格式
--       （例如 CorporateActionGeneric\Template31_CA20260730001）
-- 配合目錄 <baseDir>\CorporateActionGeneric\Template31_CA20260730001\
--          \20260807_33_NA00945001_000923.pdf 測試
-- ============================================================

-- 1. 清除舊測試 Instruction
DELETE FROM TB_eDoc_Instr WHERE templateId = 'Template31' AND ReferenceNo = 'CA20260730001';
GO

-- 2. 確保 Template31 的 reportName = CorporateActionGeneric
IF NOT EXISTS (SELECT 1 FROM TB_eDoc_ReportTemplate WHERE templateId = 'Template31')
BEGIN
    INSERT INTO [dbo].[TB_eDoc_ReportTemplate]
    (templateId, boss_statement_type, reportName, reportDescription, reportPath)
    VALUES
    ('Template31','31','CorporateActionGeneric','Corporate Action Generic (PdfChecker Test)','D:\UTBATCH\DSB\eDocReportTemplate\CorporateActionGeneric.rpt')
END
ELSE
BEGIN
    UPDATE TB_eDoc_ReportTemplate SET reportName = 'CorporateActionGeneric' WHERE templateId = 'Template31'
END
GO

-- 3. 插入 CONFIRMED Instruction（RecordCountAfterSubmit 設為 1，避免被 SKIPPED）
DECLARE @Now DATETIME = GETDATE();

INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
('Template31', 'CA20260730001', 'PdfChecker Template31 Prefixed Folder Test', 'BrClientReportTest', @Now, 1, 1, 'CONFIRMED', @Now, 'TEST', @Now, 'TEST', NULL, NULL);
GO

-- 4. 驗證
SELECT * FROM TB_eDoc_Instr WHERE templateId = 'Template31' AND ReferenceNo = 'CA20260730001';
SELECT templateId, reportName FROM TB_eDoc_ReportTemplate WHERE templateId = 'Template31';
GO
