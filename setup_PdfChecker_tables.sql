USE [BPSS]
GO

-- ================================================
-- PdfChecker - Daily check status and history tables
--
-- Change History:
-- Date       Author   Description
-- ---------- -------- --------------------------------------------------------
-- 20260729   chenqinghong Initial
-- ================================================

-- 1. Today's check result table
IF OBJECT_ID(N'dbo.TB_eDoc_PdfCheck_Daily', N'U') IS NOT NULL
    DROP TABLE [dbo].[TB_eDoc_PdfCheck_Daily]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TB_eDoc_PdfCheck_Daily](
    [id] [int] IDENTITY(1,1) NOT NULL,
    [templateId] [varchar](25) NOT NULL,
    [ReferenceNo] [varchar](25) NOT NULL,
    [Report_Title] [varchar](200) NULL,
    [Report_Date] [datetime] NULL,
    [RecordCount] [int] NULL,
    [Status] [varchar](20) NULL,
    [ErrorDetail] [nvarchar](max) NULL,
    [CheckStartTime] [datetime] NULL,
    [CheckEndTime] [datetime] NULL,
    [CreateDate] [datetime] NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_TB_eDoc_PdfCheck_Daily] PRIMARY KEY CLUSTERED ([id] ASC)
) ON [PRIMARY]
GO

SET ANSI_PADDING OFF
GO

-- 2. History table (archived daily records)
IF OBJECT_ID(N'dbo.TB_eDoc_PdfCheck_History', N'U') IS NOT NULL
    DROP TABLE [dbo].[TB_eDoc_PdfCheck_History]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TB_eDoc_PdfCheck_History](
    [id] [int] IDENTITY(1,1) NOT NULL,
    [templateId] [varchar](25) NOT NULL,
    [ReferenceNo] [varchar](25) NOT NULL,
    [Report_Title] [varchar](200) NULL,
    [Report_Date] [datetime] NULL,
    [RecordCount] [int] NULL,
    [Status] [varchar](20) NULL,
    [ErrorDetail] [nvarchar](max) NULL,
    [CheckStartTime] [datetime] NULL,
    [CheckEndTime] [datetime] NULL,
    [CreateDate] [datetime] NULL,
    [ArchiveDate] [datetime] NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_TB_eDoc_PdfCheck_History] PRIMARY KEY CLUSTERED ([id] ASC)
) ON [PRIMARY]
GO

SET ANSI_PADDING OFF
GO

-- ================================================
-- Stored Procedure  :[Sp_eDoc_PdfCheck_RotateDaily]
--
-- Change History:
-- Date       Author   Description
-- ---------- -------- --------------------------------------------------------
-- 20260729   chenqinghong Initial
--
-- Usage:
-- Archive today's daily records into history and truncate daily table
-- ================================================
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[Sp_eDoc_PdfCheck_RotateDaily]
AS
BEGIN

SET NOCOUNT ON

INSERT INTO [dbo].[TB_eDoc_PdfCheck_History]
    ([templateId], [ReferenceNo], [Report_Title], [Report_Date], [RecordCount],
     [Status], [ErrorDetail], [CheckStartTime], [CheckEndTime], [CreateDate])
SELECT
    [templateId], [ReferenceNo], [Report_Title], [Report_Date], [RecordCount],
    [Status], [ErrorDetail], [CheckStartTime], [CheckEndTime], [CreateDate]
FROM [dbo].[TB_eDoc_PdfCheck_Daily]

TRUNCATE TABLE [dbo].[TB_eDoc_PdfCheck_Daily]

END
GO

-- ================================================
-- Stored Procedure  :[Sp_eDoc_PdfCheck_LoadConfirmed]
--
-- Change History:
-- Date       Author   Description
-- ---------- -------- --------------------------------------------------------
-- 20260729   chenqinghong Initial
--
-- Usage:
-- Load all CONFIRMED instructions from TB_eDoc_Instr
-- ================================================
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[Sp_eDoc_PdfCheck_LoadConfirmed]
AS
BEGIN

SET NOCOUNT ON

SELECT templateId, ReferenceNo, Report_Title, Report_Date, RecordCount, RecordCountAfterSubmit, Status
FROM TB_eDoc_Instr WITH (NOLOCK)
WHERE Status = 'CONFIRMED'

END
GO

-- ================================================
-- Stored Procedure  :[Sp_eDoc_PdfCheck_InsertDaily]
--
-- Change History:
-- Date       Author   Description
-- ---------- -------- --------------------------------------------------------
-- 20260729   chenqinghong Initial
--
-- Usage:
-- Insert a pending daily check record
-- ================================================
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[Sp_eDoc_PdfCheck_InsertDaily]
@templateId varchar(25),
@ReferenceNo varchar(25),
@Report_Title varchar(200) = NULL,
@Report_Date datetime = NULL,
@RecordCount int = NULL
AS
BEGIN

SET NOCOUNT ON

INSERT INTO [dbo].[TB_eDoc_PdfCheck_Daily]
    ([templateId], [ReferenceNo], [Report_Title], [Report_Date], [RecordCount], [Status], [CreateDate])
VALUES
    (@templateId, @ReferenceNo, @Report_Title, @Report_Date, @RecordCount, 'PENDING', GETDATE())

SELECT SCOPE_IDENTITY() AS id

END
GO

-- ================================================
-- Stored Procedure  :[Sp_eDoc_PdfCheck_UpdateDaily]
--
-- Change History:
-- Date       Author   Description
-- ---------- -------- --------------------------------------------------------
-- 20260729   chenqinghong Initial
--
-- Usage:
-- Update daily check status and error detail
-- ================================================
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[Sp_eDoc_PdfCheck_UpdateDaily]
@id int,
@Status varchar(20),
@ErrorDetail nvarchar(max) = NULL,
@CheckStartTime datetime = NULL,
@CheckEndTime datetime = NULL
AS
BEGIN

SET NOCOUNT ON

UPDATE [dbo].[TB_eDoc_PdfCheck_Daily]
SET [Status] = @Status,
    [ErrorDetail] = @ErrorDetail,
    [CheckStartTime] = @CheckStartTime,
    [CheckEndTime] = @CheckEndTime
WHERE [id] = @id

END
GO
