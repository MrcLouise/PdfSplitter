USE [BPSS]
GO

/****** Object:  StoredProcedure [dbo].[Sp_eDoc_LoadInstructions]    Script Date: 18/06/2026 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


-- ================================================
-- Stored Procedure  :[Sp_eDoc_LoadInstructions]
--
-- Change History:
-- Date       Author   Description
-- ---------- -------- --------------------------------------------------------
-- 20260618   MRC      Initial
--
-- Usage:
-- Load instructions by status (numeric ReferenceNo only)
-- ================================================

CREATE PROC [dbo].[Sp_eDoc_LoadInstructions]
@Status varchar(20)
AS
BEGIN

SET NOCOUNT ON

SELECT templateId, ReferenceNo, Status, Report_Title, Report_Date,
       RecordCount, RecordCountAfterSubmit, createDate, createUser,
       updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime, SingleUpload,
       Attachment1, Attachment2, Attachment3, Attachment4, Attachment5,
       Attachment6, Attachment7, Attachment8, Attachment9, Attachment10,
       Attachment11, Attachment12, Attachment13, Attachment14, Attachment15,
       Attachment16, Attachment17, Attachment18, Attachment19, Attachment20
FROM TB_eDoc_Instr WITH (NOLOCK)
WHERE Status = @Status
  AND ReferenceNo IS NOT NULL
  AND LTRIM(RTRIM(ReferenceNo)) <> ''
  AND ReferenceNo NOT LIKE '%[^0-9]%'

END
GO

/****** Object:  StoredProcedure [dbo].[Sp_eDoc_UpdateStatus]    Script Date: 18/06/2026 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


-- ================================================
-- Stored Procedure  :[Sp_eDoc_UpdateStatus]
--
-- Change History:
-- Date       Author   Description
-- ---------- -------- --------------------------------------------------------
-- 20260618   MRC      Initial
--
-- Usage:
-- Update instruction status after processing
-- ================================================

CREATE PROC [dbo].[Sp_eDoc_UpdateStatus]
@templateId varchar(25),
@ReferenceNo varchar(25),
@Status varchar(20),
@updateUser varchar(10),
@StartTime datetime = NULL,
@EndTime datetime = NULL
AS
BEGIN

SET NOCOUNT ON

UPDATE TB_eDoc_Instr
SET Status = @Status,
    updateDate = GETDATE(),
    updateUser = @updateUser,
    UTDigitalStartTime = @StartTime,
    UTDigitalEndTime = @EndTime
WHERE templateId = @templateId
  AND ReferenceNo = @ReferenceNo

END
GO

/****** Object:  StoredProcedure [dbo].[Sp_eDoc_LoadReportTemplate]    Script Date: 18/06/2026 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


-- ================================================
-- Stored Procedure  :[Sp_eDoc_LoadReportTemplate]
--
-- Change History:
-- Date       Author   Description
-- ---------- -------- --------------------------------------------------------
-- 20260618   MRC      Initial
--
-- Usage:
-- Load report template by templateId
-- ================================================

CREATE PROC [dbo].[Sp_eDoc_LoadReportTemplate]
@templateId varchar(25)
AS
BEGIN

SET NOCOUNT ON

SELECT templateId, boss_statement_type, reportName, reportDescription, Permission_Code,
       reportPath, TB_DB, tableName, SP_DB, SPName, SPParmater, Schedule, Time,
       ReportNameSQL, PortfolioField, ProductField, ContractNoField, ClientIDField,
       ReportKeyField, DateParameter, tableName_ManualHandle, AllowAttachment
FROM TB_eDoc_ReportTemplate WITH (NOLOCK)
WHERE templateId = @templateId
  AND (Deleted = 0 OR Deleted IS NULL)

END
GO

/****** Object:  StoredProcedure [dbo].[Sp_eDoc_LoadReportData]    Script Date: 18/06/2026 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


-- ================================================
-- Stored Procedure  :[Sp_eDoc_LoadReportData]
--
-- Change History:
-- Date       Author   Description
-- ---------- -------- --------------------------------------------------------
-- 20260618   MRC      Initial
--
-- Usage:
-- Load report data by templateId and ReferenceNo
-- ================================================

CREATE PROC [dbo].[Sp_eDoc_LoadReportData]
@templateId varchar(25),
@ReferenceNo varchar(25)
AS
BEGIN

SET NOCOUNT ON

SELECT SeqNo, templateId, ReferenceNo, boss_statement_type, Report_Date,
       REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID,
       REPORT_KEY, ReportName, FileName, EFlag, Deleted
FROM TB_eDoc_ReportData WITH (NOLOCK)
WHERE templateId = @templateId
  AND ReferenceNo = @ReferenceNo
  AND (Deleted = 0 OR Deleted IS NULL)

END
GO

/****** Object:  StoredProcedure [dbo].[Sp_eDoc_LoadBulkUploadConfig]    Script Date: 18/06/2026 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


-- ================================================
-- Stored Procedure  :[Sp_eDoc_LoadBulkUploadConfig]
--
-- Change History:
-- Date       Author   Description
-- ---------- -------- --------------------------------------------------------
-- 20260618   MRC      Initial
--
-- Usage:
-- Load bulk upload check config by templateId
-- ================================================

CREATE PROC [dbo].[Sp_eDoc_LoadBulkUploadConfig]
@templateId varchar(25)
AS
BEGIN

SET NOCOUNT ON

SELECT id, templateId, reportPortfoliono, reportPortfolionoFormat,
       reportProduct, reportProductFormat, reportContractno,
       reportClientid, reportKey, active, deleted
FROM TB_eDoc_BulkUpload_Config WITH (NOLOCK)
WHERE templateId = @templateId
  AND active = 1
  AND (deleted = 0 OR deleted IS NULL)

END
GO
