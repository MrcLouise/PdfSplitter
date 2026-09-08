USE [BPSS]
GO

IF OBJECT_ID(N'dbo.TB_eDoc_BulkUpload_Config', N'U') IS NOT NULL
    DROP TABLE [dbo].[TB_eDoc_BulkUpload_Config]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TB_eDoc_BulkUpload_Config](
    [id] [int] IDENTITY(1,1) NOT NULL,
    [templateId] [varchar](25) NOT NULL,
    [reportPortfoliono] [varchar](10) NULL,
    [reportPortfolionoFormat] [varchar](500) NULL,
    [reportProduct] [varchar](10) NULL,
    [reportProductFormat] [varchar](500) NULL,
    [reportContractno] [varchar](10) NULL,
    [reportClientid] [varchar](10) NULL,
    [reportKey] [varchar](10) NULL,
    [active] [bit] NOT NULL DEFAULT ((1)),
    [deleted] [bit] NOT NULL DEFAULT ((0)),
    [createDate] [datetime] NOT NULL DEFAULT (GETDATE()),
    [createUser] [varchar](10) NULL,
    [updateDate] [datetime] NULL,
    [updateUser] [varchar](10) NULL,
    CONSTRAINT [PK_TB_eDoc_BulkUpload_Config] PRIMARY KEY CLUSTERED ([id] ASC)
) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_TB_eDoc_BulkUpload_Config_Template]
ON [dbo].[TB_eDoc_BulkUpload_Config] ([templateId])
WHERE [active] = 1 AND [deleted] = 0
GO

SET ANSI_PADDING OFF
GO

INSERT INTO [dbo].[TB_eDoc_BulkUpload_Config]
(templateId, reportPortfoliono, reportPortfolionoFormat, reportProduct, reportProductFormat, reportContractno, reportClientid, reportKey, active, deleted, createUser)
VALUES
('Template3', NULL, NULL, 'true', '(SELECT TOP 1 LTRIM(RTRIM(l.DESCRIPTION)) FROM HITRUST..MXFUNDTB f INNER JOIN HITRUST..MXLANGDESCTB l ON f.DESCID = l.DESCKEY WHERE LTRIM(RTRIM(f.FUNDCODE)) = LTRIM(RTRIM(REPORT_PRODUCT)))', NULL, 'true', NULL, 1, 0, 'TEST'),
('Template30', 'true', 'SUBSTRING(REPORT_PORTFOLIONO,1,8)+''-''+SUBSTRING(REPORT_PORTFOLIONO,9,1)+''-''+SUBSTRING(REPORT_PORTFOLIONO,10,3)', NULL, NULL, NULL, NULL, NULL, 1, 0, 'TEST')
GO
