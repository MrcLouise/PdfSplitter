-- ============================================================
-- PdfSplitter Windows Test - HITRUST MXFUNDTB / MXLANGDESCTB Setup
-- SQL Server 172.16.7.128
--
-- Purpose:
--   Create minimal MXFUNDTB and MXLANGDESCTB tables in HITRUST
--   so that reportProductFormat can translate REPORT_PRODUCT
--   (FUNDCODE) into the fund DESCRIPTION used for PDF matching.
-- ============================================================

USE [HITRUST]
GO

-- ============================================================
-- 1. MXLANGDESCTB : Language descriptions keyed by DESCKEY
-- ============================================================
IF OBJECT_ID(N'dbo.[MXLANGDESCTB]', N'U') IS NOT NULL
    DROP TABLE [dbo].[MXLANGDESCTB]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[MXLANGDESCTB](
    [DESCKEY] [int] NOT NULL,
    [LANGUAGEKEY] [int] NULL,
    [DESCRIPTION] [nvarchar](200) NULL,
    CONSTRAINT [PK_MXLANGDESCTB] PRIMARY KEY CLUSTERED 
    (
        [DESCKEY] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_PADDING OFF
GO

-- ============================================================
-- 2. MXFUNDTB : Fund master keyed by FUNDKEY, references DESCKEY
-- ============================================================
IF OBJECT_ID(N'dbo.[MXFUNDTB]', N'U') IS NOT NULL
    DROP TABLE [dbo].[MXFUNDTB]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[MXFUNDTB](
    [FUNDKEY] [int] NOT NULL,
    [FUNDCODE] [char](10) NOT NULL,
    [DESCID] [int] NOT NULL,
    CONSTRAINT [PK_MXFUNDTB] PRIMARY KEY CLUSTERED 
    (
        [FUNDKEY] ASC
    ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_PADDING OFF
GO

-- ============================================================
-- 3. Sample data matching the BPSS test REPORT_PRODUCT codes
-- ============================================================
INSERT INTO [dbo].[MXLANGDESCTB] ([DESCKEY], [LANGUAGEKEY], [DESCRIPTION])
VALUES
(1001, 1, N'AB (HK) European Income Portfolio (RMB-H)(AA) (Mdis-Unit)'),
(1002, 1, N'AB (HK) Asian Income Portfolio (USD)(AA) (Mdis-Unit)'),
(1003, 1, N'AB (HK) Global High Yield Portfolio (USD)(AA) (Acc-Unit)'),
(1004, 1, N'AB (HK) China A Shares Portfolio (RMB)(AA) (Acc-Unit)'),
(1005, 1, N'AB (HK) US Growth Portfolio (USD)(AA) (Acc-Unit)'),
(1006, 1, N'AB (HK) Emerging Markets Debt Portfolio (USD)(AA) (Mdis-Unit)')
GO

INSERT INTO [dbo].[MXFUNDTB] ([FUNDKEY], [FUNDCODE], [DESCID])
VALUES
( 1, 'SGN000001', 1001),   -- Template1
( 2, 'ACC8061191', 1002),  -- Template2
( 3, 'DUMMY001  ', 1001),  -- Template3 (record 1)
( 4, 'DUMMY002  ', 1001),  -- Template3 (record 2)
( 5, 'BCS01143A ', 1005),  -- Template4
( 6, '5431146P  ', 1006),  -- Template21
( 7, 'BHS01458A ', 1002)   -- Template25
GO

-- ============================================================
-- 4. Verification
-- ============================================================
SELECT f.FUNDKEY,
       LTRIM(RTRIM(f.FUNDCODE)) AS FUNDCODE,
       l.DESCRIPTION
FROM [dbo].[MXFUNDTB] f
INNER JOIN [dbo].[MXLANGDESCTB] l ON f.DESCID = l.DESCKEY
ORDER BY f.FUNDKEY
GO
