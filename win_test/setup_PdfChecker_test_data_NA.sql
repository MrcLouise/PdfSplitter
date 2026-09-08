USE [BPSS]
GO

-- ============================================================
-- PdfChecker Win11 測試資料 (NA account number 版本)
-- 配合 baseDir\DSBCouponPaymentAdvice\20250630\20260807_33_NA00945001_000923.pdf 測試
-- ============================================================

DECLARE @Now DATETIME = GETDATE();
DECLARE @TemplateId VARCHAR(25) = 'Template1';
DECLARE @ReferenceNo VARCHAR(25) = '20250630';

-- 1. 清除舊測試 Instruction
DELETE FROM TB_eDoc_Instr WHERE templateId = @TemplateId AND ReferenceNo = @ReferenceNo;
GO

-- 2. 確保 Template1 的 reportName 存在
IF NOT EXISTS (SELECT 1 FROM TB_eDoc_ReportTemplate WHERE templateId = 'Template1')
BEGIN
    INSERT INTO [dbo].[TB_eDoc_ReportTemplate]
    (templateId, boss_statement_type, reportName, reportDescription, reportPath)
    VALUES
    ('Template1','31','DSBCouponPaymentAdvice','Coupon Payment Advice','D:\UTBATCH\DSB\eDocReportTemplate\DSBCouponPaymentAdvice.rpt')
END
ELSE
BEGIN
    UPDATE TB_eDoc_ReportTemplate SET reportName = 'DSBCouponPaymentAdvice' WHERE templateId = 'Template1'
END
GO

-- 3. 插入 CONFIRMED Instruction（RecordCountAfterSubmit 設為 1，避免被 SKIPPED）
DECLARE @Now DATETIME = GETDATE();
DECLARE @TemplateId VARCHAR(25) = 'Template1';
DECLARE @ReferenceNo VARCHAR(25) = '20250630';

INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
(@TemplateId, @ReferenceNo, 'PdfChecker NA Account Test', 'BrClientReportTest', @Now, 1, 1, 'CONFIRMED', @Now, 'TEST', @Now, 'TEST', NULL, NULL);
GO

-- 4. 驗證
SELECT * FROM TB_eDoc_Instr WHERE templateId = 'Template1' AND ReferenceNo = '20250630';
GO
