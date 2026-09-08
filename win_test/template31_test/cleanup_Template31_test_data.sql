USE [BPSS]
GO

-- 清除 PdfChecker Template31 測試資料
DELETE FROM TB_eDoc_Instr WHERE templateId = 'Template31' AND ReferenceNo = 'CA20260730001';
DELETE FROM TB_eDoc_PdfCheck_Daily WHERE templateId = 'Template31' AND ReferenceNo = 'CA20260730001';
DELETE FROM TB_eDoc_PdfCheck_History WHERE templateId = 'Template31' AND ReferenceNo = 'CA20260730001';
GO
