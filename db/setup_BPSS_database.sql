-- ============================================================
-- PdfSplitter Windows Test - BPSS Database Setup Script
-- SQL Server 172.16.7.128
-- ============================================================

-- 1. Create Database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'BPSS')
BEGIN
    CREATE DATABASE [BPSS]
    ALTER DATABASE [BPSS] SET RECOVERY SIMPLE
END
GO

USE [BPSS]
GO

-- 2. Create Table: TB_eDoc_ReportTemplate
IF OBJECT_ID(N'dbo.TB_eDoc_ReportTemplate', N'U') IS NOT NULL
    DROP TABLE [dbo].[TB_eDoc_ReportTemplate]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TB_eDoc_ReportTemplate](
    [id] [int] IDENTITY(1,1) NOT NULL,
    [templateId] [varchar](25) NOT NULL,
    [boss_statement_type] [varchar](2) NOT NULL,
    [reportName] [nvarchar](200) NOT NULL,
    [reportDescription] [nvarchar](200) NOT NULL,
    [Permission_Code] [varchar](30) NULL,
    [reportPath] [nvarchar](500) NOT NULL,
    [TB_DB] [varchar](7) NULL,
    [tableName] [varchar](100) NULL,
    [SP_DB] [varchar](7) NULL,
    [SPName] [varchar](50) NULL,
    [SPParmater] [varchar](200) NULL,
    [Schedule] [varchar](100) NULL,
    [Time] [varchar](100) NULL,
    [ReportNameSQL] [varchar](200) NULL,
    [PortfolioField] [varchar](200) NULL,
    [ProductField] [varchar](200) NULL,
    [ContractNoField] [varchar](200) NULL,
    [ClientIDField] [varchar](200) NULL,
    [ReportKeyField] [varchar](200) NULL,
    [DateParameter] [varchar](200) NULL,
    [tableName_ManualHandle] [varchar](100) NULL,
    [AllowAttachment] [varchar](1) NULL,
    [Deleted] [bit] NULL
) ON [PRIMARY]
GO

GO

ALTER TABLE [dbo].[TB_eDoc_ReportTemplate] ADD  DEFAULT ((0)) FOR [Deleted]
GO

-- 3. Create Table: TB_eDoc_ReportData
IF OBJECT_ID(N'dbo.TB_eDoc_ReportData', N'U') IS NOT NULL
    DROP TABLE [dbo].[TB_eDoc_ReportData]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TB_eDoc_ReportData](
    [SeqNo] [int] IDENTITY(1,1) NOT NULL,
    [templateId] [varchar](25) NOT NULL,
    [ReferenceNo] [varchar](25) NULL,
    [boss_statement_type] [varchar](2) NOT NULL,
    [Report_Date] [datetime] NULL,
    [REPORT_PORTFOLIONO] [varchar](40) NULL,
    [REPORT_PRODUCT] [varchar](10) NULL,
    [REPORT_CONTRACTNO] [varchar](30) NULL,
    [REPORT_CLIENTID] [varchar](100) NULL,
    [REPORT_KEY] [varchar](100) NULL,
    [ReportName] [varchar](200) NULL,
    [FileName] [varchar](300) NULL,
    [EFlag] [varchar](1) NULL,
    [Deleted] [bit] NULL,
) ON [PRIMARY]
GO

-- 4. Create Table: TB_eDoc_BulkUpload_Config
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

-- 5. Create Table: TB_eDoc_Instr
IF OBJECT_ID(N'dbo.TB_eDoc_Instr', N'U') IS NOT NULL
    DROP TABLE [dbo].[TB_eDoc_Instr]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TB_eDoc_Instr](
    [templateId] [varchar](25) NOT NULL,
    [ReferenceNo] [varchar](25) NULL,
    [Report_Title] [varchar](200) NULL,
    [Permission_Code] [varchar](30) NULL,
    [Report_Date] [datetime] NULL,
    [RecordCount] [int] NULL,
    [RecordCountAfterSubmit] [int] NULL,
    [Status] [varchar](20) NULL,
    [createDate] [datetime] NULL,
    [createUser] [varchar](10) NULL,
    [updateDate] [datetime] NULL,
    [updateUser] [varchar](10) NULL,
    [UTDigitalStartTime] [datetime] NULL,
    [UTDigitalEndTime] [datetime] NULL,
    [SingleUpload] [varchar](1) NULL,
    [Attachment1] [nvarchar](200) NULL,
    [Attachment2] [nvarchar](200) NULL,
    [Attachment3] [nvarchar](200) NULL,
    [Attachment4] [nvarchar](200) NULL,
    [Attachment5] [nvarchar](200) NULL,
    [Attachment6] [nvarchar](200) NULL,
    [Attachment7] [nvarchar](200) NULL,
    [Attachment8] [nvarchar](200) NULL,
    [Attachment9] [nvarchar](200) NULL,
    [Attachment10] [nvarchar](200) NULL,
    [Attachment11] [nvarchar](200) NULL,
    [Attachment12] [nvarchar](200) NULL,
    [Attachment13] [nvarchar](200) NULL,
    [Attachment14] [nvarchar](200) NULL,
    [Attachment15] [nvarchar](200) NULL,
    [Attachment16] [nvarchar](200) NULL,
    [Attachment17] [nvarchar](200) NULL,
    [Attachment18] [nvarchar](200) NULL,
    [Attachment19] [nvarchar](200) NULL,
    [Attachment20] [nvarchar](200) NULL,
) ON [PRIMARY]
GO

GO

-- ============================================================
-- 5. Insert ReportTemplate Data (30 Templates)
-- ============================================================
INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template1','31','DSBCouponPaymentAdvice','Coupon Payment Advice','BrClientReport4','D:\UTBATCH\DSB\eDocReportTemplate\DSBCouponPaymentAdvice.rpt','DSBDB','TB_COUPON_PYMT_ADVICE_CR','DSBDB','SP_COUPON_PYMT_ADVICE','''getdate()'',''DSBL'',''All'',''ALL''','WeekDay','16:30:00','(trim(portfoliono) +''_''+ trim(fundcode))','portfoliono','fundcode',NULL,NULL,NULL,'convert(char(10),getdate(),111)','TB_COUPON_PYMT_ADVICE_Manual','Y',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template2','32','DSBDividendPaymentAdvice','Dividend Payment Advice','BrClientReport6','D:\UTBATCH\DSB\eDocReportTemplate\DSBDividendPaymentAdvice.rpt','DSBDB','TB_DIVDEND_PYMT_ADVICE_CR','DSBDB','SP_DIVDEND_PYMT_ADVICE','''getdate()'',''DSBL'',''All'',''ALL''','WeekDay','16:30:00','(trim(PortNo) +''_''+ trim(fundcode))','PortNo','fundcode',NULL,NULL,NULL,'convert(char(10),getdate(),111)','TB_DIVDEND_PYMT_ADVICE_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template3','32','DSBDividendReinvestmentAdvice','Dividend Reinvestment Advice','BrClientReport180','D:\UTBATCH\DSB\eDocReportTemplate\DSBDividendReinvestmentAdvice.rpt','DSBDB','TB_DSBAdviceReinvestmentSP_CR','HITRUST','DSBAdviceReinvestmentSP','''DSBL'',''getdate()'',''getdate()'',''ALL'',''ALL''','WeekDay','16:30:00','(trim(ClientNumber) +''_''+ trim(fundcode))','ClientNumber','fundcode',NULL,NULL,NULL,'convert(char(10),getdate(),111)','TB_DSBAdviceReinvestmentSP_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template4','34','BondNotesBulkRedemptionConfirmationNote','Bond Notes Bulk Redemption Confirmation Note','BrClientReport193','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesBulkRedemptionConfirmationNote.rpt','DSBDB','TB_RedemptionConfirmation_CR','DSBDB','SP_RedemptionConfirmation','''DSBL'',''All'',''getdate()'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_RedemptionConfirmation_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template5','34','BondNotesSalesOrderConfirmationNote_ELN','Bond Notes Sales Order Confirmation Note ELN','BrClientReport39','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesSalesOrderConfirmationNote_ELN.rpt','DSBDB','TB_BondNotesSalesOrderConfirmation_ELN_CR','DSBDB','SP_BondNotesSalesOrderConfirmation','''DSBL'',''ELN'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_BondNotesSalesOrderConfirmation_ELN_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template6','34','BondNotesSalesOrderConfirmationNote_FLN','Bond Notes Sales Order Confirmation Note FLN','BrClientReport48','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesSalesOrderConfirmationNote_FLN.rpt','DSBDB','TB_BondNotesSalesOrderConfirmation_FLN_CR','DSBDB','SP_BondNotesSalesOrderConfirmation','''DSBL'',''FLN'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_BondNotesSalesOrderConfirmation_FLN_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template7','34','BondNotesSalesOrderConfirmationNote_FXLN','Bond Notes Sales Order Confirmation Note FXLN','BrClientReport49','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesSalesOrderConfirmationNote_FXLN.rpt','DSBDB','TB_BondNotesSalesOrderConfirmation_FXLN_CR','DSBDB','SP_BondNotesSalesOrderConfirmation','''DSBL'',''FXLN'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_BondNotesSalesOrderConfirmation_FXLN_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template8','34','BondNotesSalesOrderConfirmationNote_IRLN','Bond Notes Sales Order Confirmation Note IRLN','BrClientReport45','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesSalesOrderConfirmationNote_IRLN.rpt','DSBDB','TB_BondNotesSalesOrderConfirmation_IRLN_CR','DSBDB','SP_BondNotesSalesOrderConfirmation','''DSBL'',''IRLN'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_BondNotesSalesOrderConfirmation_IRLN_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template9','34','BondNotesSalesOrderConfirmationNote_ELIBONDS','Bond Notes Sales Order Confirmation Note ELI Bonds','BrClientReport35','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesSalesOrderConfirmationNote_ELIBONDS.rpt','DSBDB','TB_BondNotesSalesOrderConfirmation_ELIBONDS_CR','DSBDB','SP_BondNotesSalesOrderConfirmation','''DSBL'',''ELI BONDS'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_BondNotesSalesOrderConfirmation_ELIBONDS_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template10','34','BondNotesSalesOrderConfirmationNote_MKTBONDS','Bond Notes Sales Order Confirmation Note MKT Bonds','BrClientReport194','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesSalesOrderConfirmationNote_MKTBONDS.rpt','DSBDB','TB_BondNotesSalesOrderConfirmation_MKTBONDS_CR','DSBDB','SP_BondNotesSalesOrderConfirmation','''DSBL'',''MKT BONDS'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_BondNotesSalesOrderConfirmation_MKTBONDS_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template11','34','BondNotesSalesOrderConfirmationNote_OTCBONDS','Bond Notes Sales Order Confirmation OTC/PBD Bonds','BrClientReport34','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesSalesOrderConfirmationNote_OTCBONDS.rpt','DSBDB','TB_BondNotesSalesOrderConfirmation_OTCBONDS_CR','DSBDB','SP_BondNotesSalesOrderConfirmation','''DSBL'',''OTC BONDS'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_BondNotesSalesOrderConfirmation_OTCBONDS_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template12','34','BondNotesSalesOrderConfirmationNote_PBDFXLN','Bond Notes Sales Order Confirmation PBD FXLN','BrClientReport58','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesSalesOrderConfirmationNote_PBDFXLN.rpt','DSBDB','TB_BondNotesSalesOrderConfirmation_PBDFXLN_CR','DSBDB','SP_BondNotesSalesOrderConfirmation','''DSBL'',''PBD FXLN'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_BondNotesSalesOrderConfirmation_PBDFXLN_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template13','34','DSBRedemptionConfirmation','Investment Fund Redemption Confirmation Note','BrClientReport182','D:\UTBATCH\DSB\eDocReportTemplate\DSBRedemptionConfirmation.rpt','DSBDB','TB_DSBRedemptionConfirmationSP_CR','HITRUST','DSBRedemptionConfirmationSP','''DSBL'',''All'',''getdate()'',''All'',''All''','WeekDay','16:30:00','(trim(ClientNumber) +''_''+ trim(FundCode))','ClientNumber','FundCode','ContractNo',NULL,NULL,'convert(char(10),getdate(),111)','TB_DSBRedemptionConfirmationSP_Manual','Y',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template14','35','BondNotesPurchaseOrderConfirmationNote_ELIBonds','Bond Notes Purchase Order Confirmation Note ELI Bonds','BrClientReport33','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesPurchaseOrderConfirmationNote_ELIBonds.rpt','DSBDB','TB_NotePurchaseOrderConfirmation_RBD_ELIBONDS_CR','DSBDB','SP_NotePurchaseOrderConfirmation_RBD','''DSBL'',''ELI BONDS'',''All'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_NotePurchaseOrderConfirmation_RBD_ELIBONDS_Manual','Y',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template15','35','BondNotesPurchaseOrderConfirmationNote_ELN','Bond Notes Purchase Order Confirmation Note ELN','BrClientReport38','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesPurchaseOrderConfirmationNote_ELN.rpt','DSBDB','TB_NotePurchaseOrderConfirmation_RBD_ELN_CR','DSBDB','SP_NotePurchaseOrderConfirmation_RBD','''DSBL'',''ELN'',''All'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_NotePurchaseOrderConfirmation_RBD_ELN_Manual','Y',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template16','35','BondNotesPurchaseOrderConfirmationNote_FLN','Bond Notes Purchase Order Confirmation Note FLN','BrClientReport47','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesPurchaseOrderConfirmationNote_FLN.rpt','DSBDB','TB_NotePurchaseOrderConfirmation_RBD_FLN_CR','DSBDB','SP_NotePurchaseOrderConfirmation_RBD','''DSBL'',''FLN'',''All'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_NotePurchaseOrderConfirmation_RBD_FLN_Manual','Y',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template17','35','BondNotesPurchaseOrderConfirmationNote_FXLN','Bond Notes Purchase Order Confirmation Note FXLN','BrClientReport42','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesPurchaseOrderConfirmationNote_FXLN.rpt','DSBDB','TB_NotePurchaseOrderConfirmation_RBD_FXLN_CR','DSBDB','SP_NotePurchaseOrderConfirmation_RBD','''DSBL'',''FXLN'',''All'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_NotePurchaseOrderConfirmation_RBD_FXLN_Manual','Y',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template18','35','BondNotesPurchaseOrderConfirmationNote_IPOBonds','Bond Notes Purchase Order Confirmation Note IPO Bonds','BrClientReport12','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesPurchaseOrderConfirmationNote_IPOBonds.rpt','DSBDB','TB_NotePurchaseOrderConfirmation_RBD_IPOBONDS_CR','DSBDB','SP_NotePurchaseOrderConfirmation_RBD','''DSBL'',''IPO BONDS'',''All'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_NotePurchaseOrderConfirmation_RBD_IPOBONDS_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template19','35','BondNotesPurchaseOrderConfirmationNote_IRLN','Bond Notes Purchase Order Confirmation Note IRLN','BrClientReport44','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesPurchaseOrderConfirmationNote_IRLN.rpt','DSBDB','TB_NotePurchaseOrderConfirmation_RBD_IRLN_CR','DSBDB','SP_NotePurchaseOrderConfirmation_RBD','''DSBL'',''IRLN'',''All'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_NotePurchaseOrderConfirmation_RBD_IRLN_Manual','Y',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template20','35','BondNotesPurchaseOrderConfirmationNote_MKTBonds','Bond Notes Purchase Order Confirmation Note MKT Bonds','BrClientReport32','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesPurchaseOrderConfirmationNote_MKTBonds.rpt','DSBDB','TB_NotePurchaseOrderConfirmation_RBD_MKTBONDS_CR','DSBDB','SP_NotePurchaseOrderConfirmation_RBD','''DSBL'',''MKT BONDS'',''All'',''ALL'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_NotePurchaseOrderConfirmation_RBD_MKTBONDS_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template21','35','BondNotesPurchaseOrderConfirmationNote','Bond Notes Purchase Order Confirmation Note OTC/PBD Bonds','BrClientReport192','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesPurchaseOrderConfirmationNote.rpt','DSBDB','TB_NotePurchaseOrderConfirmation_PBD_CR','DSBDB','SP_NotePurchaseOrderConfirmation_PBD','''DSBL'',''All'',''getdate()'',''ALL'',''OTC BONDS''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_NotePurchaseOrderConfirmation_PBD_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template22','35','BondNotesPurchaseOrderConfirmationNote_PBDFXLN','Bond Notes Purchase Order Confirmation Note PBD FXLN','BrClientReport57','D:\UTBATCH\DSB\eDocReportTemplate\BondNotesPurchaseOrderConfirmationNote_PBDFXLN.rpt','DSBDB','TB_NotePurchaseOrderConfirmation_PBD_PBDFXLN_CR','DSBDB','SP_NotePurchaseOrderConfirmation_PBD','''DSBL'',''All'',''getdate()'',''ALL'',''FXLN''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_NotePurchaseOrderConfirmation_PBD_PBDFXLN_Manual','Y',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template23','35','DSBSubscriptionConfirmation','Investment Fund Subscription Confirmation Note','BrClientReport183','D:\UTBATCH\DSB\eDocReportTemplate\DSBSubscriptionConfirmation.rpt','DSBDB','TB_DSBSubComfirmationSP_CR','HITRUST','DSBSubComfirmationSP','''DSBL'',''All'',''getdate()'',''ALL'',''ALL''','WeekDay','16:30:00','(trim(ClientNumber) +''_''+ trim(FundCode))','ClientNumber','FundCode','ContractNo',NULL,NULL,'convert(char(10),getdate(),111)','TB_DSBSubComfirmationSP_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template24','35','DSBSwitchingConfirmation','Investment Fund Switching Confirmation Note','BrClientReport184','D:\UTBATCH\DSB\eDocReportTemplate\DSBSwitchingConfirmation.rpt','DSBDB','TB_DSBSwitchingConfirmationSP_CR','HITRUST','DSBSwitchingConfirmationSP','''DSBL'',''All'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(ClientNumber) +''_''+ trim(OutFundCode))','ClientNumber','OutFundCode','ContractNo',NULL,NULL,'convert(char(10),getdate(),111)','TB_DSBSwitchingConfirmationSP_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template25','38','TransferInOrderConfirmationNote','Bond Notes Transfer In Order Confirmation Note','BrClientReport198','D:\UTBATCH\DSB\eDocReportTemplate\TransferInOrderConfirmationNote.rpt','DSBDB','TB_TransferInOrderConfirmationNote_CR','DSBDB','SP_TransferInOrderConfirmationNote','''DSBL'',''All'',''getdate()'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_TransferInOrderConfirmationNote_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template26','38','TransferOutOrderConfirmationNote','Bond Notes Transfer Out Order Confirmation Note','BrClientReport199','D:\UTBATCH\DSB\eDocReportTemplate\TransferOutOrderConfirmationNote.rpt','DSBDB','TB_TransferOutOrderConfirmationNote_CR','DSBDB','SP_TransferOutOrderConfirmationNote','''DSBL'',''All'',''getdate()'',''getdate()'',''ALL''','WeekDay','16:30:00','(trim(NoteAccountNo) +''_''+ trim(fundcode))','NoteAccountNo','fundcode','ContractNumber',NULL,NULL,'convert(char(10),getdate(),111)','TB_TransferOutOrderConfirmationNote_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template27','38','Third_Party_Transfer_Cfm_Note','Confirmation Notes for Third-Party Transfer','BrClientReport175','D:\UTBATCH\DSB\eDocReportTemplate\Third_Party_Transfer_Cfm_Note.rpt','DSBDB','TB_Third_Party_Transfer_Cfm_Notes_CR','BPSS','sp_Third_Party_Transfer_Cfm_Notes','''getdate()'',''getdate()'',''DSBL'',''All''','WeekDay','16:30:00','(trim(portfoliono) +''_''+ trim(fundcode))','portfoliono','fundcode','ctractno',NULL,NULL,'convert(char(10),getdate(),111)','TB_Third_Party_Transfer_Cfm_Notes_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template28','38','ConversionConfirmation','Fund Conversion Confirmation','BrClientReport84','D:\UTBATCH\DSB\eDocReportTemplate\ConversionConfirmation.rpt','DSBDB','TB_Conversion_Confirmation_CR','BPSS','SP_Conversion_Confirmation','''DSBL'',''All'',''getdate()'',''All''','WeekDay','16:30:00','(trim(ClientNumber) +''_''+ trim(FundCode))','ClientNumber','FundCode','ContractNo',NULL,NULL,'convert(char(10),getdate(),111)','TB_Conversion_Confirmation_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template29','38','DSBTransferConfirmation','Investment Fund Confirmation Of Transfer','BrClientReport185','D:\UTBATCH\DSB\eDocReportTemplate\DSBTransferConfirmation.rpt','DSBDB','TB_DSBTransferConfirmation_CR','HITRUST','DSBTransferConfirmationSP','''DSBL'',''getdate()'',''All''','WeekDay','16:30:00','(trim(ClientNumber) +''_''+ trim(FundCode))','ClientNumber','FundCode','ContractNo',NULL,NULL,'convert(char(10),getdate(),111)','TB_DSBTransferConfirmation_Manual','N',0)

INSERT INTO [dbo].[TB_eDoc_ReportTemplate] VALUES
('Template30','33','DSBMonthlyStatement','DSB Monthly statement','BrClientReport59','D:\UTBATCH\DSB\eDocReportTemplate\DSBMonthlyStatement.rpt','DSBDB','DSBCSCustMasterLinkTB_CurMth','DSBDB','SP_MonthlyStatement_eDoc','''getdate()'',''ALL'',''ALL''','WeekDay','16:30:00','(trim(PortNum))','PortNum',null,null,null,'CSLinkKey','Convert(char(10),Dateadd(Month, DateDiff(Month,-1,getdate())-1,-1),111)','DSBCSCustMasterLinkTB_Manual','Y',0)
GO

-- ============================================================
-- 6. Insert TB_eDoc_BulkUpload_Config Test Data
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
('Template30', 'true', 'SUBSTRING(REPORT_PORTFOLIONO,1,8)+''-''+SUBSTRING(REPORT_PORTFOLIONO,9,1)+''-''+SUBSTRING(REPORT_PORTFOLIONO,10,3)', NULL, NULL, NULL, NULL, NULL, 1, 0, 'TEST')
GO

-- ============================================================
-- 7. Insert Test Instructions & ReportData
-- ============================================================
DECLARE @Now DATETIME = GETDATE()

-- Template1 : DSBCouponPaymentAdvice (Boss Type 31)
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
('Template1', '20250605', 'DSB Coupon Payment Advice Test', 'BrClientReport4', @Now, 2, NULL, 'SUBMITTED', @Now, 'TEST', NULL, NULL, NULL, NULL)

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
('Template1', '20250605', '31', @Now, 'UT0094500001', 'SGN000001', NULL, NULL, NULL, NULL, '20260529_31_UT0094500001_SGN000001_000010.pdf', 'N', 0)

-- Template2 : DSBDividendPaymentAdvice (Boss Type 32)
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
('Template2', '2025060532', 'DSB Dividend Payment Advice Test', 'BrClientReport6', @Now, 1, NULL, 'SUBMITTED', @Now, 'TEST', NULL, NULL, NULL, NULL)

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
('Template2', '2025060532', '32', @Now, 'UT0040311001', 'ACC8061191', NULL, NULL, NULL, NULL, '20260529_32_UT0040311001_ACC8061191_000018.pdf', 'N', 0)

-- Template3 : DSBDividendReinvestmentAdvice (Boss Type 32, only Name of the Fund, no product code)
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
('Template3', '2025060537', 'DSB Dividend Reinvestment Advice Test', 'BrClientReport180', @Now, 2, NULL, 'SUBMITTED', @Now, 'TEST', NULL, NULL, NULL, NULL)

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
('Template3', '2025060537', '32', @Now, NULL, 'DUMMY001', NULL, 'UT0511571001', NULL, NULL, '20260529_32_UT0511571001_DUMMY001_000019.pdf', 'N', 0),
('Template3', '2025060537', '32', @Now, NULL, 'DUMMY002', NULL, 'UT0727831002', NULL, NULL, '20260529_32_UT0727831002_DUMMY002_000020.pdf', 'N', 0)

-- Template4 : BondNotesBulkRedemptionConfirmationNote (Boss Type 34)
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
('Template4', '2025060534', 'Bond Notes Bulk Redemption Test', 'BrClientReport193', @Now, 1, NULL, 'SUBMITTED', @Now, 'TEST', NULL, NULL, NULL, NULL)

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
('Template4', '2025060534', '34', @Now, 'UT0012750001', 'BCS01143A', 'RED-00932581', NULL, NULL, NULL, '20260529_34_UT0012750001_BCS01143A_000030.pdf', 'N', 0)

-- Template21 : BondNotesPurchaseOrderConfirmationNote (Boss Type 35)
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
('Template21', '2025060535', 'Bond Notes Purchase Order Test', 'BrClientReport192', @Now, 1, NULL, 'SUBMITTED', @Now, 'TEST', NULL, NULL, NULL, NULL)

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
('Template21', '2025060535', '35', @Now, 'UT0503915001', '5431146P', 'SUB-01124455', NULL, NULL, NULL, '20260529_35_UT0503915001_5431146P_001204.pdf', 'N', 0)

-- Template25 : TransferInOrderConfirmationNote (Boss Type 38)
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
('Template25', '2025060525', 'Transfer In Order Confirmation Test', 'BrClientReport198', @Now, 1, NULL, 'SUBMITTED', @Now, 'TEST', NULL, NULL, NULL, NULL)

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
('Template25', '2025060525', '38', @Now, 'UT0311620001', 'BHS01458A', 'TRI-01116994', NULL, NULL, NULL, '20260529_38_UT0311620001_BHS01458A_000063.pdf', 'N', 0)

-- Template30 : DSBMonthlyStatement (Boss Type 33)
INSERT INTO [dbo].[TB_eDoc_Instr]
(templateId, ReferenceNo, Report_Title, Permission_Code, Report_Date, RecordCount, RecordCountAfterSubmit, Status, createDate, createUser, updateDate, updateUser, UTDigitalStartTime, UTDigitalEndTime)
VALUES
('Template30', '2025060533', 'DSB Monthly Statement Test', 'BrClientReport59', @Now, 1, NULL, 'SUBMITTED', @Now, 'TEST', NULL, NULL, NULL, NULL)

INSERT INTO [dbo].[TB_eDoc_ReportData]
(templateId, ReferenceNo, boss_statement_type, Report_Date, REPORT_PORTFOLIONO, REPORT_PRODUCT, REPORT_CONTRACTNO, REPORT_CLIENTID, REPORT_KEY, ReportName, FileName, EFlag, Deleted)
VALUES
('Template30', '2025060533', '33', @Now, 'UT0004976001', NULL, NULL, NULL, NULL, NULL, '20260529_33_UT0004976001_001280.pdf', 'N', 0)
GO

-- ============================================================
-- 8. Verify data
-- ============================================================
SELECT 'Templates' AS CheckItem, COUNT(*) AS Count FROM TB_eDoc_ReportTemplate
UNION ALL
SELECT 'Test Instructions (SUBMITTED)', COUNT(*) FROM TB_eDoc_Instr WHERE Status = 'SUBMITTED'
UNION ALL
SELECT 'Test ReportData', COUNT(*) FROM TB_eDoc_ReportData
UNION ALL
SELECT 'Test BulkUpload Config', COUNT(*) FROM TB_eDoc_BulkUpload_Config
GO
