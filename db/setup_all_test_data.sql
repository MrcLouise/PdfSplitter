USE [BPSS]
GO

-- ============================================================
-- PdfSplitter Test Data Script
-- Rules:
--   1. ReferenceNo must be non-empty and numeric only (no letters)
--   2. SingleUpload = 'Y' means one PDF, no split, merge attachments only
--   3. BulkUpload PDF naming: {ReferenceNo}.pdf
--   4. Attachment folder: Attachment\ (files listed in Attachment1~20, no ReferenceNo subfolder)
-- ============================================================

-- Add SingleUpload column if missing
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[TB_eDoc_Instr]') AND name = 'SingleUpload'
)
BEGIN
ALTER TABLE [dbo].[TB_eDoc_Instr] ADD [SingleUpload] [varchar](1) NULL;
END
GO

-- Clear old test data (legacy + new numeric refs)
DELETE FROM TB_eDoc_ReportData WHERE ReferenceNo LIKE 'TEST20250605%' OR ReferenceNo LIKE '20250605%';
DELETE FROM TB_eDoc_Instr WHERE ReferenceNo LIKE 'TEST20250605%' OR ReferenceNo LIKE '20250605%';
DELETE FROM TB_eDoc_BulkUpload_Config WHERE templateId IN ('Template1','Template2','Template3','Template4','Template21','Template25','Template30');
GO

-- ============================================================
-- BulkUpload Config
-- ============================================================
INSERT INTO [dbo].[TB_eDoc_BulkUpload_Config]
(templateId, reportPortfoliono, reportPortfolionoFormat, reportProduct, reportProductFormat, reportContractno, reportClientid, reportKey, active, deleted, createUser)
VALUES
('Template1', 'true', NULL, 'true', NULL, NULL, NULL, NULL, 1, 0, 'TEST'),
('Template2', 'true', NULL, 'true', NULL, NULL, NULL, NULL, 1, 0, 'TEST'),
('Template3', NULL, NULL, 'true', '(SELECT TOP 1 LTRIM(RTRIM(l.DESCRIPTION)) FROM HITRUST..MXFUNDTB f INNER JOIN HITRUST..MXLANGDESCTB l ON f.DESCID = l.DESCKEY WHERE LTRIM(RTRIM(f.FUNDCODE)) = LTRIM(RTRIM(REPORT_PRODUCT)))', NULL, 'true', NULL, 1, 0, 'TEST'),
('Template4', 'true', NULL, 'true', NULL, 'true', NULL, NULL, 1, 0, 'TEST'),
('Template21', 'true', NULL, 'true', NULL, 'true', NULL, NULL, 1, 0, 'TEST'),
('Template25', 'true', NULL, 'true', NULL, 'true', NULL, NULL, 1, 0, 'TEST'),
('Template30', 'true', 'SUBSTRING(REPORT_PORTFOLIONO,1,8)+''-''+SUBSTRING(REPORT_PORTFOLIONO,9,1)+''-''+SUBSTRING(REPORT_PORTFOLIONO,10,3)', NULL, NULL, NULL, NULL, NULL, 1, 0, 'TEST');
GO

DECLARE @Now DATETIME = GETDATE();

-- ============================================================
-- Template1 : DSBCouponPaymentAdvice (Boss Type 31) - BULK SPLIT
-- PDF: BulkUpload\20250605.pdf (rename from TEST20250605.pdf)
-- ReportData: 1 record; multi-page PDF splits by page
-- Attachment: Attachment\Template1_202615001_1.pdf.pdf, Attachment\Template1_202615001_2.pdf.pdf
-- ============================================================
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, SingleUpload, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime, Attachment1, Attachment2)
VALUES
    ('Template1', '20250605', 'DSB Coupon Payment Advice Test', 'BrClientReport4', @Now, 2, NULL, 'SUBMITTED', NULL, @Now, 'TEST', NULL, NULL, NULL, NULL, 'Template1_202615001_1.pdf.pdf', 'Template1_202615001_2.pdf.pdf');

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
    ('Template1', '20250605', '31', @Now, 'UT0094500001', 'SGN000001', NULL, NULL, NULL, NULL, '20260529_31_UT0094500001_SGN000001_000010.pdf', 'N', 0);

-- ============================================================
-- Template1 : DSBCouponPaymentAdvice - SINGLE UPLOAD
-- PDF: BulkUpload\2025060599.pdf (copy from TEST20250605.pdf)
-- ReportData: exactly 1 record, no page split
-- Attachment: same files in Attachment\ root folder
-- ============================================================
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, SingleUpload, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime, Attachment1, Attachment2)
VALUES
    ('Template1', '2025060599', 'DSB Coupon Payment Advice Single Upload Test', 'BrClientReport4', @Now, 1, NULL, 'SUBMITTED', 'Y', @Now, 'TEST', NULL, NULL, NULL, NULL, 'Template1_202615001_1.pdf.pdf', 'Template1_202615001_2.pdf.pdf');

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
    ('Template1', '2025060599', '31', @Now, 'UT0094500001', 'SGN000001', NULL, NULL, NULL, NULL, '20260529_31_UT0094500001_SGN000001_000099.pdf', 'N', 0);

-- ============================================================
-- Template2 : DSBDividendPaymentAdvice (Boss Type 32)
-- PDF: BulkUpload\2025060532.pdf (rename from TEST20250605_32.pdf)
-- WRONG filename test for filename composition validation
-- ============================================================
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, SingleUpload, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
    ('Template2', '2025060532', 'DSB Dividend Payment Advice Test', 'BrClientReport6', @Now, 1, NULL, 'SUBMITTED', NULL, @Now, 'TEST', NULL, NULL, NULL, NULL);

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
    ('Template2', '2025060532', '32', @Now, 'UT0040311001', 'ACC8061191', NULL, NULL, NULL, NULL, '20260529_32_UT0040311001_ACC8061191_000018.pdf', 'N', 0);

-- ============================================================
-- Template3 : DSBDividendReinvestmentAdvice (Boss Type 32)
-- PDF: BulkUpload\2025060537.pdf (rename from TEST20250605_R.pdf)
-- Only Name of the Fund in PDF, no product code
-- ============================================================
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, SingleUpload, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
    ('Template3', '2025060537', 'DSB Dividend Reinvestment Advice Test', 'BrClientReport180', @Now, 2, NULL, 'SUBMITTED', NULL, @Now, 'TEST', NULL, NULL, NULL, NULL);

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
    ('Template3', '2025060537', '32', @Now, NULL, 'DUMMY001', NULL, 'UT0511571001', NULL, NULL, '20260529_32_UT0511571001_DUMMY001_000019.pdf', 'N', 0),
    ('Template3', '2025060537', '32', @Now, NULL, 'DUMMY002', NULL, 'UT0727831002', NULL, NULL, '20260529_32_UT0727831002_DUMMY002_000020.pdf', 'N', 0);

-- ============================================================
-- Template4 : BondNotesBulkRedemptionConfirmationNote (Boss Type 34)
-- PDF: BulkUpload\2025060534.pdf
-- ============================================================
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, SingleUpload, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
    ('Template4', '2025060534', 'Bond Notes Bulk Redemption Test', 'BrClientReport193', @Now, 1, NULL, 'SUBMITTED', NULL, @Now, 'TEST', NULL, NULL, NULL, NULL);

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
    ('Template4', '2025060534', '34', @Now, 'UT0012750001', 'BCS01143A', 'RED-00932581', NULL, NULL, NULL, '20260529_34_UT0012750001_BCS01143A_000030.pdf', 'N', 0);

-- ============================================================
-- Template21 : BondNotesPurchaseOrderConfirmationNote (Boss Type 35)
-- PDF: BulkUpload\2025060535.pdf
-- ============================================================
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, SingleUpload, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
    ('Template21', '2025060535', 'Bond Notes Purchase Order Test', 'BrClientReport192', @Now, 1, NULL, 'SUBMITTED', NULL, @Now, 'TEST', NULL, NULL, NULL, NULL);

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
    ('Template21', '2025060535', '35', @Now, 'UT0503915001', '5431146P', 'SUB-01124455', NULL, NULL, NULL, '20260529_35_UT0503915001_5431146P_001204.pdf', 'N', 0);

-- ============================================================
-- Template25 : TransferInOrderConfirmationNote (Boss Type 38)
-- PDF: BulkUpload\2025060525.pdf (rename from TEST20250605_T25.pdf)
-- ============================================================
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, SingleUpload, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
    ('Template25', '2025060525', 'Transfer In Order Confirmation Test', 'BrClientReport198', @Now, 1, NULL, 'SUBMITTED', NULL, @Now, 'TEST', NULL, NULL, NULL, NULL);

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
    ('Template25', '2025060525', '38', @Now, 'UT0311620001', 'BHS01458A', 'TRI-01116994', NULL, NULL, NULL, '20260529_38_UT0311620001_BHS01458A_000063.pdf', 'N', 0);

-- ============================================================
-- Template30 : DSBMonthlyStatement (Boss Type 33)
-- PDF: BulkUpload\20250605.pdf (rename from TEST20250605M.pdf)
-- Account in PDF has hyphens: UT000497-6-001
-- ============================================================
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, SingleUpload, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
    ('Template30', '2025060533', 'DSB Monthly Statement Test', 'BrClientReport59', @Now, 1, NULL, 'SUBMITTED', NULL, @Now, 'TEST', NULL, NULL, NULL, NULL);

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
    ('Template30', '2025060533', '33', @Now, 'UT0004976001', NULL, NULL, NULL, NULL, NULL, '20260529_33_UT0004976001_001280.pdf', 'N', 0);

-- ============================================================
-- Verify data
-- ============================================================
SELECT 'Eligible Instructions (SUBMITTED, numeric ReferenceNo)' AS CheckItem,
       COUNT(*) AS Count
FROM TB_eDoc_Instr
WHERE Status = 'SUBMITTED'
  AND ReferenceNo IS NOT NULL
  AND LTRIM(RTRIM(ReferenceNo)) <> ''
  AND ReferenceNo NOT LIKE '%[^0-9]%'
UNION ALL
SELECT 'Single Upload Instructions', COUNT(*)
FROM TB_eDoc_Instr
WHERE Status = 'SUBMITTED' AND SingleUpload = 'Y'
UNION ALL
SELECT 'Test ReportData', COUNT(*)
FROM TB_eDoc_ReportData
WHERE ReferenceNo LIKE '20250605%';
GO
