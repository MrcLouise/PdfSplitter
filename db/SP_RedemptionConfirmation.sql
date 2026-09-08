USE [DSBDB]
GO

/****** Object:  StoredProcedure [dbo].[SP_RedemptionConfirmation]    Script Date: 26/3/2026 3:09:04 pm ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
















-- =============================================================================
-- Author:		Unknown
-- ALTER  date: Unknown
-- Description:	Unknown
--
-- Modification:
-- 
-- Date       Name                 Trace Code	Description
-- ---------- -------------------- ----------	--------------------------------------------------
-- 2004-05-18 Mendel Lam           1.0			Confirmation for Redempton note
-- 2004-09-06 Clerence Lo          2.0			Add condition in the OUTER JOIN criteria :
--												LEFT OUTER JOIN VW_UDF_REDEEM_SECURITY  VW_SECURITY   ON ( hitrust..MXPORTFOLIOTB.PORTFOLIONO = VW_SECURITY.PORTFOLIONO
--												AND 
--												hitrust..MXFUNDTB.FUNDCODE = VW_SECURITY.FUNDCODE )
-- 2004-09-07 Clerence Lo          3.0			Bulk Redemption UAT Problem : Change the decimals place of PRICE field from 2 to 4
-- 2004-09-24 Ben                  4.0			Remove checking B to suppress commission and the calculation for total settle
-- 2005-10-07 Gary								FIX UNITCLASS
-- 2005-12-15 BC								fix bonds/notes class code
-- 2006-01-23 BC								add remarks2; handle zero coupon rate
-- 2006-03-02                      BC060302		quick fix for unknown bug
-- 2006-05-03									remove quick fix BC060302
-- 2006-05-04                      BC060504		fix bug for reading security a/c view
-- 2007-06-27 Louie Lee            BCM07007		re-arrange the record order for confirmation log report
-- 2007-09-12 Louie Lee            PDM07604		add fundcode in the confirmation
-- 2010-09-24 Roger Seto						Fix to include PBD portfolios
-- 2011-11-11 Kevin Ma             KM20111111	Added Pre-deducted Coupon Amount, Coupon Handling Fee, Last Net Coupon Amount
-- 2011-12-13 Kevin Ma             KM20111213	Removed FUNDCODE condition in WHERE clause 
-- 2012-02-16 Thomas Lam 						SCR: BCM11020 add country code = 'HM' (Hold Mail) for filtering
--												Add output field "countryiso"				
-- 2012-05-08 Thomas Lam						rewrite the settlement account logic
-- 2012-06-20 Thomas Lam						ELI Phase 2  Update Bond Note Confirmations Product Reference field
--												from  Stockx to user define field 
-- 2012-06-21 Thomas Lam						Update the Change of Destination : All, Local, Oversea and Hold Mail
-- 2012-08-14 Enqvist Lau 		   EL20120814	Remove the filter (MXPROFILEADDRTB.DEFAULTADDR = 1) and Change the 
--												Join criteria to DSBProfAddVW.
-- 2014-01-14 Ksun Chan			   BCM13016_099 Add BCM Section
-- 2014-08-21 Ksun Chan			   NIL			Release Upgrade to HiTrust7.0 - Adjust position of "SHARE"
-- 2014-11-14 Henry Ho Add Portfolio Type '0' for Bond Financing
-- 2015-04-28	Henry Ho		Fixing duplicate join using ctractno
-- 2016-04-26	Henry Ho		Display Cash Settlement Account when Last Coupon >0 
-- 2016-09-20	Henry Ho		PBD16037	extend decimal place of price from 4 to 8 
-- 2020-12-09 	DECO     		SARDRD20002	UPDATE COLUMN STOCK_CODE FROM INT TO CHAR(20) / Add space store stock name with code
-- 2023-04-06  Penny Chu  CBP2 account display format
--PC20230914	SCRWMD23004	IRLN & FLN & ELN if ELI_reference exist, use ELI_reference as stockx
--							if ELI_reference not exist, use stockx 
-- 2024-07-10	Penny Chu		SCRWMD24025		RBD W8Ben
-- 2025-05-12	Penny Chu		SCRWMD24062 add FXLN
-- 2026-03-23	Penny Chu		SCRPBD25034 Digitalization put @comp to result
--								Add Logic for Digital or Phyiscal
--								Add fundcode and EFlag to result

-- Test: [SP_RedemptionConfirmation] 'DSBL', 'ALL', '2003/04/03', ''
--EXEC SP_RedemptionConfirmation 'DSBL','ALL','2020/01/13','2020/01/14','ALL'
-- =============================================================================
CREATE        PROCEDURE [dbo].[SP_RedemptionConfirmation]
(
    @Company char(20),
    @ContractNumber char(40) ,
    @PricingDate char(10),
    @LastCouponDate char(10),
    @Destination char(40)
)
AS
BEGIN

/*
--
DECLARE	@Company as char(20)
DECLARE @ContractNumber as char(40) 
DECLARE @PricingDate as char(10)
DECLARE @LastCouponDate as char(10)
DECLARE @Destination as char(40)


SET	@Company ='BCML'
SET @ContractNumber = 'ALL'
SET @PricingDate = '2014/01/14'
SET @LastCouponDate = '2014/01/14'
SET @Destination = 'ALL'
--
*/

/*Penny 20260323 Start*/
select *
into #TB_PORTFOLIO_E_FLAG
from DSBDB..VW_PORTFOLIO_E_FLAG_CONTRACTNOTE
    
select * 
into #TB_Manual
from dsbdb..TB_RedemptionConfirmation_Manual
where convert(varchar(10),ReportDate,111) = @PricingDate

If (select count(*) from #TB_Manual) = 0
BEGIN
	insert into #TB_Manual
	select * 
	from dsbdb..TB_RedemptionConfirmation_Manual_History
	where convert(varchar(10),ReportDate,111) = @PricingDate
END

/*Penny 20260323 End*/

    SELECT NoteAccountNo = hitrust..MXPORTFOLIOTB.portfoliono
          ,CustomerName  = hitrust..DSBProfAddVW.PortName
          ,AddressLine1  = hitrust..DSBPROFADDVW.PortAdd1
          ,AddressLine2  = hitrust..DSBPROFADDVW.PortAdd2
          ,AddressLine3  = hitrust..DSBPROFADDVW.PortAdd3
          ,AddressLine4  = hitrust..DSBPROFADDVW.PortAdd4
          ,ContractNumber = hitrust..MXCTRACTTB.CTRACTNO
/* Thomas 20120620 Start */
--,IssueNo        = hitrust..MXFUNDTB.STOCKX
,IssueNo                   =
(case when (isnull(hitrust.dbo.MXUNITCLASSTB.CLASSCODE,'')like '1E%')   
then isnull(eli_ref.eli_charfield,'')
when isnull(sub_class.subclass_charfield,'') in ('IRLN','FLN','ELN','FXLN')  --PC20230914	--PC20250512
THEN isnull(eli_ref.eli_charfield, hitrust..mxfundtb.STOCKX)				   --PC20230914
	 else isnull(hitrust..mxfundtb.STOCKX,'') end ) 
/* Thomas 20120620 end */
--          ,NoteName     = cast ( rtrim(ltrim(TB_MXLANGDESCTB_FUNDTB.DESCRIPTION)) + ' (' + rtrim(ltrim(hitrust..MXFUNDTB.fundcode))    + ')' as varchar (80) )   ,
          ,NoteName       = TB_MXLANGDESCTB_FUNDTB.DESCRIPTION
          ,CouponRateDesc = BPSS..TB_BOND_MASTER.COUPON_RATE_DESC
--          ,CouponRate     = BPSS..TB_BOND_MASTER.COUPON_RATE * 100
          ,CouponRate     = ISNULL(BPSS..TB_BOND_MASTER.COUPON_RATE,0) * 100
          ,CouponRateDesc_B5 = ISNULL(BPSS..TB_BOND_MASTER.COUPON_RATE_DESC_B5, ''), -- Coupon Rate Description (entered value with chinese big5 code set)
CouponRateDesc_TC	=isnull(BPSS..TB_BOND_MASTER.COUPON_RATE_DESC_TC, ''),	-- Coupon Rate Description (entered value with chinese big5 code set)
IssueDate             	=BPSS..TB_BOND_MASTER.ISSUE_DT,
MaturityDate          	=BPSS..TB_BOND_MASTER.MATURITY_DT,
IntPaymentSeq         	=BPSS..TB_BOND_MASTER.INT_PAY_FRQ,
IntPaymentSeq_TC       	=BPSS..TB_BOND_MASTER.INT_PAY_FRQ_TC,
ExtendedMaturityDate  	=BPSS..TB_BOND_MASTER.MATURITY_DATE_EXT,
StrikePrice		=BPSS..TB_BOND_MASTER.STRIKE_PRICE,
StrikePriceCCY		=BPSS..TB_BOND_MASTER.STRIKE_PRICE_CCY,

StrikePriceRemarks1	=isnull(BPSS..TB_BOND_MASTER.REMARKS1,''),
StrikePriceRemarks2	=isnull(BPSS..TB_BOND_MASTER.REMARKS2,''),

FixingDate		=BPSS..TB_BOND_MASTER.FIXING_DT,

ValueDTDesc		=BPSS..TB_BOND_MASTER.VALUE_DT_DESC,			-- Valuation Date (Eng.)
ValueDTDescB5	=BPSS..TB_BOND_MASTER.VALUE_DT_DESC_B5,		-- Valuation Date (Chi.)

MaturityDTDesc		=BPSS..TB_BOND_MASTER.MATURITY_DT_DESC,		-- Maturity Date (Eng.)
MaturityDTDescB5	=BPSS..TB_BOND_MASTER.MATURITY_DT_DESC_B5,		-- Maturity Date (Chi.)
MaturityDTDescTC	=BPSS..TB_BOND_MASTER.MATURITY_DT_DESC_TC,		-- Maturity Date (Chi.)

TransactionDate       	= hitrust..MXCTRACTTB.ORDERDATE,
SettlementDate          = hitrust..MXCTRACTTB.PRICINGDATE,

Price			= case when hitrust..MXCTRACTTB.REFERENCE = 'CASH' then
-- Modified by Clerence Lo [2004/09/07] [Version 3.0] [UAT Problem : Change the decimals place of PRICE field from 2 to 4] [Begin]
--				100 * cast(hitrust..MXCTRACTTB.PRICE as decimal(8,4))
-- HH20160920 change decimals place of price field from 4 to 8
				--cast (100 * hitrust..MXCTRACTTB.PRICE as decimal(8,4))
				cast (100 * hitrust..MXCTRACTTB.PRICE as decimal(12,8))
--HH20160920
-- Modified by Clerence Lo [2004/09/07] [Version 3.0] [UAT Problem : Change the decimals place of PRICE field from 2 to 4] [End]
			  else case when hitrust..MXCTRACTTB.REFERENCE = 'STOCK'  then
				0.00 end end,

RedemptionAmount       	= case when hitrust..MXCTRACTTB.REFERENCE = 'CASH' then
               		       CAST(hitrust..MXCTRACTTB.NoUnit * hitrust..MXCTRACTTB.PRICE as decimal(15,2))
--               		       cast(round(isnull(hitrust.dbo.MXTRANFINSTB.GROSS,0.00),2) * hitrust..MXCTRACTTB.PRICEas decimal(15,2))
			  else case when hitrust..MXCTRACTTB.REFERENCE = 'STOCK' and VW_CASH.NUMERICFIELD >= 0.00 then
				VW_CASH.NUMERICFIELD 
			  else
				0.00 end end, 
----BCM13016_099 - 2014-01-14----
/*
LastCouponAmount        = case when @Company = 'MVBL' then
                                    isnull(TB_BONDTXN_M.COUPON,0)
                          else     isnull(TB_BONDTXN_D.COUPON,0) end,
*/
LastCouponAmount = case @company
						when 'DSBL'	then isnull(TB_BONDTXN_D.COUPON,0)
						when 'MVBL'	then isnull(TB_BONDTXN_M.COUPON,0)
						when 'BCML'	then isnull(TB_BONDTXN_B.COUPON,0)
						else	-1	-- for OTHER		
				   end,
----BCM13016_099 - 2014-01-14----
----BCM13016_099 - 2014-01-14----
/*		   
LastCouponCcy           = case when @Company = 'MVBL' then
                                    TB_BONDTXN_M.TXCCY
                          else      TB_BONDTXN_D.TXCCY end,
*/
LastCouponCcy = case @Company
						when 'DSBL'	then TB_BONDTXN_D.TXCCY
						when 'MVBL'	then TB_BONDTXN_M.TXCCY
						when 'BCML'	then TB_BONDTXN_B.TXCCY
						else ''	-- for OTHER		
				   end,
----BCM13016_099 - 2014-01-14----
----BCM13016_099 - 2014-01-14----
/*		
---- BEGIN: KM20111111
LastCouponEntitled  = CASE WHEN @Company = 'MVBL' THEN TB_BONDTXN_M.COUPON_ENTITLED
                           ELSE TB_BONDTXN_D.COUPON_ENTITLED
                      END,
*/
LastCouponEntitled  = CASE @Company
						when 'DSBL'	then TB_BONDTXN_D.COUPON_ENTITLED
						when 'MVBL'	then TB_BONDTXN_M.COUPON_ENTITLED
						when 'BCML'	then TB_BONDTXN_B.COUPON_ENTITLED
						else	''	-- for OTHER		
				   end,
----BCM13016_099 - 2014-01-14----
----BCM13016_099 - 2014-01-14----
/*
LastCouponHandlingFees = CASE WHEN @Company = 'MVBL' THEN TB_BONDTXN_M.HANDLING_FEE
                              ELSE TB_BONDTXN_D.HANDLING_FEE
                         END,
*/
LastCouponHandlingFees = CASE @Company
						when 'DSBL'	then TB_BONDTXN_D.HANDLING_FEE
						when 'MVBL'	then TB_BONDTXN_M.HANDLING_FEE
						when 'BCML'	then TB_BONDTXN_B.HANDLING_FEE
						else	-1	-- for OTHER		
				   end,
----BCM13016_099 - 2014-01-14----
----BCM13016_099 - 2014-01-14----
/*
LastNetCouponAmount = CASE WHEN @Company = 'MVBL' THEN ISNULL(TB_BONDTXN_M.COUPON, 0)
                           ELSE ISNULL(TB_BONDTXN_D.COUPON, 0)
                      END,
*/
LastNetCouponAmount = CASE @Company
						when 'DSBL'	then TB_BONDTXN_D.COUPON
						when 'MVBL'	then TB_BONDTXN_M.COUPON
						when 'BCML'	then TB_BONDTXN_B.COUPON
						else	-1	-- for OTHER		
				   end,
----BCM13016_099 - 2014-01-14----
/*Penny Chu 20240716 Start*/
LastCouponTax = CASE @Company
						when 'DSBL'	then TB_BONDTXN_D.TAX_AMOUNT
						when 'MVBL'	then 0
						when 'BCML'	then 0
						else	-1	-- for OTHER		
				   end,
/*Penny Chu 20240716 End*/
PortfolioType = CASE WHEN SUBSTRING(HITRUST..MXPORTFOLIOTB.PORTFOLIONO, 9, 1) IN (2,5,7,8) THEN 'PBD'
                     ELSE 'RBD'
                END,
---- END: KM20111111

RedemptionShares       	= case when hitrust..MXCTRACTTB.REFERENCE = 'CASH' then
				0.00
			  else case when hitrust..MXCTRACTTB.REFERENCE = 'STOCK' then
				VW_SHARES.NUMERICFIELD   end end,

--select CONVERT(VARCHAR(5), RIGHT('00000'+LTRIM(RTRIM(STOCK_CODE)) , 5)) + ' / ' + STOCK_NAME_E  + ' / '  + rtrim(ltrim(cast(STOCK_LOT as char(7)))) as STOCK
StockCode		=  TB_STOCK.STOCK_NAME_E + ' (' +
(CASE WHEN ISNUMERIC(VW_STOCKCODE.CHARFIELD) = 1 THEN
		CONVERT(VARCHAR(5), RIGHT('00000'+LTRIM(RTRIM(VW_STOCKCODE.CHARFIELD)) , 5)) 
	ELSE
		LTRIM(RTRIM(VW_STOCKCODE.CHARFIELD))
	END) + ')' 
,
--StockCode		= cast(VW_STOCKCODE.CHARFIELD as dec(18,0)),

NotionalAmount       	= case when ISNUMERIC(hitrust..MXCTRACTTB.NoUnit)= 1 then CAST(hitrust..MXCTRACTTB.NoUnit AS money) else 0 end,
--Commission            	= case when upper(hitrust..MXFUNDTB.EXTERNALID) ='B' then 0 else hitrust..MXTRANFINSTB.COMMISSION end,
Commission            	= hitrust..MXTRANFINSTB.COMMISSION,
--HandlingFees          	= case when upper(hitrust..MXFUNDTB.EXTERNALID) ='B' then 0 else hitrust..MXTRANFINSTB.TAX end,
HandlingFees          	= hitrust..MXTRANFINSTB.TAX,
--TotalSettlementAmount 	= Case when upper(isnull(hitrust..MXFUNDTB.EXTERNALID,'')) = 'B'and hitrust..MXCTRACTTB.REFERENCE = 'CASH' then
--               		    cast(hitrust..MXCTRACTTB.NoUnit * hitrust..MXCTRACTTB.PRICE - hitrust..MXTRANFINSTB.TAX as decimal(15,2))
--			  else Case when upper(isnull(hitrust..MXFUNDTB.EXTERNALID,'')) = 'B'and hitrust..MXCTRACTTB.REFERENCE = 'STOCK' and VW_CASH.NUMERICFIELD >= 0.00 then
--			    cast(VW_CASH.NUMERICFIELD  - hitrust..MXTRANFINSTB.TAX as decimal(15,2))
--			  else Case when upper(isnull(hitrust..MXFUNDTB.EXTERNALID,'')) <> 'B'and hitrust..MXCTRACTTB.REFERENCE = 'STOCK' and VW_CASH.NUMERICFIELD >= 0.00 then
--			    cast(VW_CASH.NUMERICFIELD  - hitrust..MXTRANFINSTB.COMMISSION - hitrust..MXTRANFINSTB.TAX as decimal(15,2))
--			  else Case when upper(isnull(hitrust..MXFUNDTB.EXTERNALID,'')) <> 'B'and hitrust..MXCTRACTTB.REFERENCE = 'CASH' then
--              		    cast(hitrust..MXCTRACTTB.NoUnit * hitrust..MXCTRACTTB.PRICE - hitrust..MXTRANFINSTB.COMMISSION - hitrust..MXTRANFINSTB.TAX as decimal(15,2))
--			  else 0.00 end end end end,
TotalSettlementAmount 	= Case when hitrust..MXCTRACTTB.REFERENCE = 'CASH' then
               		  	cast(hitrust..MXTRANFINSTB.NET as decimal(15,2))
			  else	Case when hitrust..MXCTRACTTB.REFERENCE = 'STOCK' and VW_CASH.NUMERICFIELD >= 0.00 then
			    		cast(VW_CASH.NUMERICFIELD - hitrust..MXTRANFINSTB.COMMISSION - hitrust..MXTRANFINSTB.TAX as decimal(15,2))
			  	else	0.00
				end
			end,
/*
SettlementAccountNo   	= Case when hitrust..MXCTRACTTB.REFERENCE = 'CASH' then
				left(ltrim(hitrust..MXSETTLEACTB.ACNO),2) + '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),3,3) +  '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),6,10)  +'  ( CASH)'
			  else Case when hitrust..MXCTRACTTB.REFERENCE = 'STOCK' and VW_CASH.NUMERICFIELD >= 0.00 and VW_SHARES.NUMERICFIELD >= 0.00 then
				left(ltrim(hitrust..MXSETTLEACTB.ACNO),2) + '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),3,3) +  '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),6,10) + '/' +  VW_SECURITY.METHOD 
			  else Case when hitrust..MXCTRACTTB.REFERENCE = 'STOCK' then
				VW_SECURITY.METHOD + '   (SHARES)'
			  end end end,
*/
/*<<HH20160426
SettlementAccountNo   	= Case when hitrust..MXCTRACTTB.REFERENCE = 'CASH' then
				left(ltrim(hitrust..MXSETTLEACTB.ACNO),2) + '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),3,3) +  '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),6,10)  +'  (CASH)'
			  else Case when hitrust..MXCTRACTTB.REFERENCE = 'STOCK' and VW_CASH.NUMERICFIELD >= 0.00 and VW_SHARES.NUMERICFIELD >= 0.00 then
				left(ltrim(hitrust..MXSETTLEACTB.ACNO),2) + '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),3,3) +  '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),6,10) +'  (CASH)'
			  end end ,
*/
SettlementAccountNo   	= Case when 
				(hitrust..MXCTRACTTB.REFERENCE = 'CASH' )
				OR (hitrust..MXCTRACTTB.REFERENCE = 'STOCK' and VW_CASH.NUMERICFIELD >= 0.00 and VW_SHARES.NUMERICFIELD >= 0.00)
				--LastNetCouponAmount
				OR ((CASE @Company
						when 'DSBL'	then TB_BONDTXN_D.COUPON
						when 'MVBL'	then TB_BONDTXN_M.COUPON
						when 'BCML'	then TB_BONDTXN_B.COUPON
						else	-1	-- for OTHER		
				   end)>0)
				then
					case when len(rtrim(hitrust..MXSETTLEACTB.ACNO)) = 12 then
								left(ltrim(hitrust..MXSETTLEACTB.ACNO),3) + '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),4,3) +  '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),7,5) +  '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),12,1) -- formatted as XXX-XXX-XXXXX-X
								when len(rtrim(hitrust..MXSETTLEACTB.ACNO)) = 11 then
								left(ltrim(hitrust..MXSETTLEACTB.ACNO),3) + '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),4,3) +  '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),7,5) -- formatted as XXX-XXX-XXXXX
								else
								left(ltrim(hitrust..MXSETTLEACTB.ACNO),2) + '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),3,3) +  '-' + substring(ltrim(hitrust..MXSETTLEACTB.ACNO),6,10) -- formatted as bb-ttt-nnnnn
								end
			   end ,			  
			  --HH20160426>>
-- KM20111213 >>>
---- BC060504 begin
--/* 
--SecurityAccountNo  	 	=  Case when hitrust..MXCTRACTTB.REFERENCE = 'STOCK' and VW_CASH.NUMERICFIELD >= 0.00 and VW_SHARES.NUMERICFIELD >= 0.00 then
--				 VW_SECURITY.METHOD +  '   (SHARES)'	-- BC060302
--			  else Case when hitrust..MXCTRACTTB.REFERENCE = 'STOCK' then
--				 VW_SECURITY.METHOD +  '   (SHARES)'	-- BC060302
--			  end end ,
--*/
--SecurityAccountNo = case when  hitrust..MXCTRACTTB.REFERENCE = 'STOCK' then
--			(select VW_SECURITY.METHOD +  '   (SHARES)' from
--			VW_UDF_REDEEM_SECURITY  VW_SECURITY
--			where vw_security.portfoliokey = hitrust..MXPORTFOLIOTB.PORTFOLIOkey
--			and vw_security.fundcode = hitrust..MXFUNDTB.FUNDCODE)
--		else ''
--		   end,
---- BC060504 end

--KS20140821
/*
SecurityAccountNo = CASE WHEN HITRUST..MXCTRACTTB.REFERENCE = 'STOCK' THEN (SELECT VW_SECURITY.METHOD + '  (SHARES)' 
                                                                              FROM VW_UDF_REDEEM_SECURITY AS VW_SECURITY
                                                                             WHERE VW_SECURITY.PORTFOLIOKEY = HITRUST..MXPORTFOLIOTB.PORTFOLIOKEY)
                         ELSE ''
                    END,
*/                  
SecurityAccountNo = CASE WHEN HITRUST..MXCTRACTTB.REFERENCE = 'STOCK' THEN (SELECT LEFT(VW_SECURITY.METHOD,16) + N'(股票SHARES)' 
                                                                              FROM VW_UDF_REDEEM_SECURITY AS VW_SECURITY
                                                                             WHERE VW_SECURITY.PORTFOLIOKEY = HITRUST..MXPORTFOLIOTB.PORTFOLIOKEY)
                         ELSE ''
                    END,                    
--KS20140821
                    
-- <<< KM20111213

NetInvestmentAmount   	= case when ISNUMERIC(hitrust..MXTRANFINSTB.GROSS)= 1  then CAST(hitrust..MXTRANFINSTB.GROSS  AS money) else 0 end,

AccruedInterest   	= case when dsbdb.dbo.VW_UDF_ACCRUEDINTEREST.DESCRIPTION is not null then
				cast(isnull(dsbdb.dbo.VW_UDF_ACCRUEDINTEREST.NUMERICFIELD,0) as float)		-- ACCRUED Interest
			else
				0.0	--isnull(hitrust.dbo.MXTRANFINSTB.FUNDMANAGERFEE, 0.0)
			end,


ExcessAmount          	= case when ISNUMERIC(hitrust..MXCTRACTTB.SSREF)= 1  then CAST(REPLACE(REPLACE(hitrust..MXCTRACTTB.SSREF ,',',''),'$','')   AS money) else 0 end
                                   - isnull(hitrust..MXTRANFINSTB.NET,0.0) -- to solve user entered comma or dollar sign to SSREF field
				   - cast(isnull(dsbdb.dbo.VW_UDF_ACCRUEDINTEREST.NUMERICFIELD,0) as float),			

CCY                   		= hitrust..MXCURRENCYTB.CURRENCYISO,

NOTENAME_TC 		= BPSS..TB_BOND_MASTER.BONDNAME_TC_B5,  -- entered value with chinese big5 code set

--NOTENAME_UN 		= BPSS..TB_BOND_MASTER.BONDNAME_TC,  -- entered value with chinese big5 code set
NOTENAME_UN 		= case when BPSS..TB_BOND_MASTER.BONDNAME_TC is  null  then '(' + rtrim(hitrust..MXFUNDTB.fundcode)  + ')' else BPSS..TB_BOND_MASTER.BONDNAME_TC + ' (' + rtrim(hitrust..MXFUNDTB.fundcode)  + ')' end ,  
StrikePriceFlag		= ISNULL(BPSS..TB_BOND_MASTER.STRIKE_PRICE_FLAG,0),
CLASS			= hitrust.dbo.MXUNITCLASSTB.CLASSCODE
-- vvvv More than enough for debug vvvv --
    ,PricingDate =left(convert(char, hitrust..MXCTRACTTB.PRICINGDATE ,111),10),
    Company     =hitrust..MXCOMPANYTB.SHORTNAME,
    TranStatus  =TB_MXLANGDESCTB_CTSTATUSTB.DESCRIPTION
-- ^^^^ More than enough for debug ^^^^ --
,Remarks        =isnull(BPSS..TB_BOND_MASTER.REMARKS2,'')        -- BC
/* Thomas 20120306 Start */
,"countryiso" = hitrust..MXCOUNTRYTB.countryiso
/* Thomas 20120306 End */
,"fundcode" = MXFUNDTB.FUNDCODE
,"comp" = @Company
,case when TB_E_FLAG.PORTFOLIONO is not null then 'Y' else 'N' end as EFlag
-------------------------------------------
from hitrust..MXCTRACTTB with (nolock)
LEFT OUTER JOIN hitrust..MXACCOUNTTB with (nolock)  ON hitrust..MXACCOUNTTB.ACCTKEY = hitrust..MXCTRACTTB.ACCTKEY

INNER JOIN hitrust..MXPORTFOLIOTB with (nolock)     ON hitrust..MXPORTFOLIOTB.PORTFOLIOKEY = hitrust..MXACCOUNTTB.PORTFOLIOKEY

--LEFT OUTER JOIN hitrust..DSBProfAddVW ON hitrust..DSBProfAddVW.PortKey = hitrust..MXPORTFOLIOTB.PORTFOLIOKEY
LEFT OUTER JOIN hitrust..DSBProfAddVW ON hitrust..DSBProfAddVW.PortKey = hitrust..MXPORTFOLIOTB.PORTFOLIOKEY

/*Roger Seto - 12Feb2009 Handle mxaccounttb.unitclasskey; no more unitclass in mxctracttb */
left JOIN hitrust..MXUNITCLASSTB with (nolock) ON hitrust..MXUNITCLASSTB.UNITCLASSKEY  = hitrust..MXACCOUNTTB.UNITCLASSKEY
INNER JOIN hitrust..MXFUNDTB with (nolock)          ON hitrust..MXFUNDTB.FUNDKEY = hitrust..MXUNITCLASSTB.FUNDKEY --original set
--INNER JOIN hitrust..MXFUNDTB          ON hitrust..MXFUNDTB.FUNDKEY = hitrust..MXACCOUNTTB.FUNDKEY
/*Roger Seto - 12Feb2009 Handle mxaccounttb.unitclasskey; no more unitclass in mxctracttb */
LEFT OUTER JOIN hitrust..MXLANGDESCTB       TB_MXLANGDESCTB_FUNDTB 	with (nolock)
	ON TB_MXLANGDESCTB_FUNDTB.DESCKEY = hitrust..MXFUNDTB.DESCID AND TB_MXLANGDESCTB_FUNDTB.LANGUAGEKEY = 1

LEFT OUTER JOIN hitrust..MXATTACHMENTTB with (nolock) ON hitrust..MXATTACHMENTTB.ATTACHNO     = hitrust..MXFUNDTB.Fundkey

LEFT OUTER JOIN hitrust..MXTRANFINSTB with (nolock)  ON hitrust..MXTRANFINSTB.TRANSACTIONKEY = hitrust..MXCTRACTTB.CTRACTKEY
             AND hitrust..MXTRANFINSTB.CURRENCYKEY    =hitrust..MXCTRACTTB.DEALCCY
/* Thomas 20120508 Start */
/*
LEFT OUTER JOIN hitrust..MXPORTSETTLEINSTTB 
	ON hitrust..MXPORTSETTLEINSTTB.PORTFOLIOKEY      =hitrust..MXPORTFOLIOTB.PORTFOLIOKEY
             AND hitrust..MXPORTSETTLEINSTTB.SETTLEINSTTYPE IN
		(SELECT DESCKEY FROM hitrust.dbo.MXLANGDESCTB
		WHERE DESCRIPTION =  'Redemption'   --- special for sales confirmation note
		AND LANGUAGEKEY = 1)
*/
Left outer join hitrust..mxsettlesplittb with (nolock) on hitrust..MXCTRACTTB.ctractkey = hitrust..mxsettlesplittb.transactionkey
	and hitrust..mxsettlesplittb.split = 100
LEFT OUTER JOIN hitrust..MXSETTLEACTB with (nolock)       --TB_I
    ON (hitrust..MXSETTLEACTB.SETTLEACKEY      =hitrust..mxsettlesplittb.SETTLEKEY
    --ON (hitrust..MXSETTLEACTB.SETTLEACKEY      =hitrust..MXPORTSETTLEINSTTB.SETTLEACCOUNT
    and hitrust..MXSETTLEACTB.DELETED=0) -- DELETED=0 i.e. not terminated
/* Thomas 20120508 End */

-- referenced from DSBTRANSACTIONVIEWVW
INNER JOIN hitrust..MXCTSTATUSTB with (nolock) ON hitrust..MXCTSTATUSTB.CTSTATUSKEY       =hitrust..MXCTRACTTB.CTSTATUSKEY

INNER JOIN hitrust..MXLANGDESCTB       TB_MXLANGDESCTB_CTSTATUSTB with (nolock)	--TB_K 
	ON TB_MXLANGDESCTB_CTSTATUSTB.DESCKEY           =hitrust..MXCTSTATUSTB.DESCID

LEFT OUTER JOIN hitrust..MXCTRACTSUBTYPETB  with (nolock) --TB_L 
	ON hitrust..MXCTRACTSUBTYPETB.CTRACTSUBTYPEKEY  =hitrust..MXCTRACTTB.CTRACTSUBTYPE

LEFT OUTER JOIN hitrust..MXLANGDESCTB       TB_MXLANGDESCTB_CTRACTSUBTYPETB	 with (nolock)--TB_M 
	ON TB_MXLANGDESCTB_CTRACTSUBTYPETB.DESCKEY           =hitrust..MXCTRACTSUBTYPETB.DESCID

-- referenced from DSBsubConfirmationSP
INNER JOIN hitrust..MXCOMPANYTB with (nolock) ON hitrust..MXCOMPANYTB.COMPANYKEY = hitrust..MXFUNDTB.COMPANYKEY

INNER JOIN hitrust..MXLANGDESCTB            TB_MXLANGDESCTB_COMPANYTB  with (nolock) 	--TB_O 
	ON TB_MXLANGDESCTB_COMPANYTB.DESCKEY           = hitrust..MXCOMPANYTB.DESCID 
	AND TB_MXLANGDESCTB_COMPANYTB.LANGUAGEKEY = 1

INNER JOIN hitrust..MXCURRENCYTB  with (nolock) ON hitrust..MXCURRENCYTB.CURRENCYKEY = hitrust..MXFUNDTB.CURRENCY

-- Note Name in Chinese --
INNER JOIN BPSS..TB_BOND_MASTER  with (nolock)           -- TB_Q 
	ON (BPSS..TB_BOND_MASTER.FUNDKEY=hitrust..MXFUNDTB.FUNDKEY 


		AND BPSS..TB_BOND_MASTER.COMPANYKEY=hitrust..MXFUNDTB.COMPANYKEY)
-- UnitClass
/*
LEFT JOIN hitrust.dbo.MXUNITCLASSTB 
	ON hitrust..MXUNITCLASSTB.FUNDKEY    = hitrust..MXFUNDTB.FUNDKEY
*/
LEFT OUTER JOIN dsbdb.dbo.VW_UDF_ACCRUEDINTEREST
	on dsbdb.dbo.VW_UDF_ACCRUEDINTEREST.CTRACTKEY = hitrust..MXCTRACTTB.CTRACTKEY
	and dsbdb.dbo.VW_UDF_ACCRUEDINTEREST.COMPANY = hitrust.dbo.mxportfoliotb.COMPANY

LEFT OUTER JOIN dsbdb.dbo.VW_UDF_REDEEM_SHARES    VW_SHARES     ON hitrust..MXCTRACTTB.CTRACTNO       = VW_SHARES.CTRACTNO
LEFT OUTER JOIN dsbdb.dbo.VW_UDF_REDEEM_CASH      VW_CASH       ON hitrust..MXCTRACTTB.CTRACTNO       = VW_CASH.CTRACTNO
LEFT OUTER JOIN dsbdb.dbo.VW_UDF_REDEEM_STOCKCODE VW_STOCKCODE  ON hitrust..MXCTRACTTB.CTRACTNO       = VW_STOCKCODE.CTRACTNO
-- BC060504 begin
/*
LEFT OUTER JOIN VW_UDF_REDEEM_SECURITY  VW_SECURITY   ON ( hitrust..MXPORTFOLIOTB.PORTFOLIONO = VW_SECURITY.PORTFOLIONO
								-- Added By Clerence Lo [2004/09/06] [Begin] [Version 2.0] [Add condition in the OUTER JOIN criteria]
										AND 
									hitrust..MXFUNDTB.FUNDCODE = VW_SECURITY.FUNDCODE )
								-- Added By Clerence Lo [2004/09/06] [End]  [Version 1.0] [Add condition in the OUTER JOIN criteria]
*/
-- BC060504 end
LEFT OUTER JOIN  TB_RTGL_FXRATE_REDEMPTION   TB_FXRATE  with (nolock)   ON TB_FXRATE.CURRENCYKEY = hitrust..MXFUNDTB.CURRENCY  -- get FX Rate for FundCCY to HKD
LEFT OUTER JOIN  dsbdb.dbo.TB_BOND_PYMT_TXN  TB_BONDTXN_D  with (nolock) ON TB_BONDTXN_D.PORTFOLIOKEY     = hitrust..MXPORTFOLIOTB.PORTFOLIOKEY and
																			TB_BONDTXN_D.FUNDKEY          = hitrust..MXFUNDTB.FUNDKEY and
																			TB_BONDTXN_D.COUPON_PYMT_DATE = @LastCouponDate

LEFT OUTER JOIN  mvbdb.dbo.TB_BOND_PYMT_TXN  TB_BONDTXN_M  with (nolock) ON TB_BONDTXN_M.PORTFOLIOKEY     = hitrust..MXPORTFOLIOTB.PORTFOLIOKEY and
																			TB_BONDTXN_M.FUNDKEY          = hitrust..MXFUNDTB.FUNDKEY and
																			TB_BONDTXN_M.COUPON_PYMT_DATE = @LastCouponDate
----BCM13016_099 - KS20140114----
LEFT OUTER JOIN  bcmdb.dbo.TB_BOND_PYMT_TXN  TB_BONDTXN_B  with (nolock) ON TB_BONDTXN_B.PORTFOLIOKEY     = hitrust..MXPORTFOLIOTB.PORTFOLIOKEY and
																			TB_BONDTXN_B.FUNDKEY          = hitrust..MXFUNDTB.FUNDKEY and
																			TB_BONDTXN_B.COUPON_PYMT_DATE = @LastCouponDate
----BCM13016_099 - KS20140114----
LEFT OUTER JOIN BPSS..TB_STOCK_INFO TB_STOCK  with (nolock) ON TRIM(TB_STOCK.STOCK_CODE) = TRIM(VW_STOCKCODE.CHARFIELD)
-------------------------------------------






/* 20120814 Enqvist - Start */

--/* Thomas 20120216 Start */
--LEFT OUTER JOIN hitrust..MXPROFILEADDRTB MXPROFILEADDRTB ON
-- 	       	(hitrust..MXPORTFOLIOTB.PROFILEKEY = MXPROFILEADDRTB.PROFILEKEY AND MXPROFILEADDRTB.DEFAULTADDR =1
--		and MXPROFILEADDRTB.DELETED = '0'
--		)

  INNER JOIN hitrust..MXPROFILEADDRTB MXPROFILEADDRTB  with (nolock) ON 
			 hitrust..DSBProfAddVW.AddrKey = MXPROFILEADDRTB.CLTADDRESSKEY
/* 20120814 Enqvist - End   */




--INNER JOIN hitrust..MXPROFILEADDRTB ON
--		hitrust..MXPORTADDR.addresskey = hitrust..MXPROFILEADDRTB.cltaddresskey
--		and hitrust..MXPROFILEADDRTB.DELETED = '0'
LEFT OUTER JOIN hitrust..MXCOUNTRYTB  with (nolock) ON
                MXPROFILEADDRTB.COUNTRY = hitrust..MXCOUNTRYTB.COUNTRYKEY
/* Thomas 20120216 End */
/* Thomas 20120620 Start */
left join 
(
select distinct udf_eli.xrefkey as xrefkey, udf_eli.charfield as eli_charfield
from hitrust..MXFUNDTB f with (nolock)
inner join hitrust..mxuserdefinedfieldtb udf_eli  with (nolock)
	on  udf_eli.xrefkey = f.fundkey
	and udf_eli.deleted = 0
inner join hitrust..mxuserdefinedfieldtypetb udft_eli  with (nolock)
	on udf_eli.userdefinedfieldtypekey = udft_eli.userdefinedfieldtypekey
inner join hitrust..mxlangdesctb ud_eli_lng  with (nolock) on udft_eli.descid = ud_eli_lng.desckey 
	and ud_eli_lng.description  LIKE '%ELI_REFERENCE%'
) as eli_ref on eli_ref.xrefkey = hitrust..mxfundtb.fundkey
/* Thomas 20120620 End */
/* Penny Chu 20230914 Start */
	LEFT JOIN
	(
		SELECT distinct udf_subclass.xrefkey as xrefkey, udf_subclass.charfield as subclass_charfield
		FROM hitrust..MXFUNDTB f  with (nolock)
		inner join hitrust..mxuserdefinedfieldtb udf_subclass  with (nolock)
			on  udf_subclass.xrefkey = f.fundkey
			and udf_subclass.deleted = 0
		inner join hitrust..mxuserdefinedfieldtypetb udft_subclass  with (nolock)
			on udf_subclass.userdefinedfieldtypekey = udft_subclass.userdefinedfieldtypekey
		inner join hitrust..mxlangdesctb ud_subclass_lng  with (nolock) on udft_subclass.descid = ud_subclass_lng.desckey 
			and ud_subclass_lng.description  LIKE 'SUB_CLASS%'
	) as sub_class on sub_class.xrefkey = hitrust..mxfundtb.fundkey
/* Penny Chu 20230914 End */
/*Penny 20260326 Start*/
LEFT JOIN #TB_PORTFOLIO_E_FLAG TB_E_FLAG ON rtrim(Mxportfoliotb.PORTFOLIONO) = rtrim(TB_E_FLAG.PORTFOLIONO)
LEFT JOIN #TB_Manual TB_Manual on rtrim(Mxportfoliotb.PORTFOLIONO) = rtrim(TB_Manual.MANUAL_PORFOLIONO) and rtrim(MXFUNDTB.FUNDCODE) = rtrim(TB_Manual.MANUAL_PRODUCT) and rtrim(hitrust..MXCTRACTTB.CTRACTNO) = rtrim(TB_Manual.MANUAL_CONTRACTNO)
/*Penny 20260326 End*/
where
(hitrust..MXCTRACTTB.CTRACTNO = @ContractNumber or @ContractNumber = 'ALL')
/* Thomas 20120621 Start */
	and ( 
	(upper(@Destination) = 'ALL') 
	or ( (upper(@Destination) = 'HOLD MAIL') and (countryiso = 'HM') and TB_E_FLAG.PORTFOLIONO is null) 
	or  ( (upper(@Destination) = 'LOCAL') and ((countryiso = 'HKG') or (countryiso is null) ) and TB_E_FLAG.PORTFOLIONO is null)
	or  ( (upper(@Destination) = 'OVERSEA') and ( (countryiso not in ('HM' , 'HKG')) and (countryiso is not null) ) and TB_E_FLAG.PORTFOLIONO is null) 
	or  (upper(@Destination) = 'ECOPY' and TB_E_FLAG.PORTFOLIONO is not null)
	or (upper(@Destination) = 'HOLD MAIL MANUAL' and TB_Manual.MANUAL_PORFOLIONO is not null and TB_Manual.MANUAL_PRODUCT is not null and TB_Manual.MANUAL_CONTRACTNO is not null)	
	)
/* Thomas 20120621 End */
AND hitrust..MXCTRACTTB.TRANCODEKEY = 'BaRedemptions'    -- TranType = 'Subscription'
AND TB_MXLANGDESCTB_CTSTATUSTB.DESCRIPTION IN ('Priced', 'Settled/Registered')  -- BEN: ADD "Settled/Registered" FOR NORMAL SUBSCRIPTION RATHER THEN "Priced" ONLY
AND SUBSTRING(isnull(TB_MXLANGDESCTB_CTRACTSUBTYPETB.DESCRIPTION ,' '),1,6) <> 'ERRREV'
AND ABS(hitrust..MXCTRACTTB.CANCELLED) = 0.0
AND left(convert(char, hitrust..MXCTRACTTB.PRICINGDATE ,111),10) = @PricingDate
AND hitrust..MXCOMPANYTB.SHORTNAME = @Company

--AND hitrust..MXCTRACTTB.SSREF is not null
--AND substring(hitrust..MXPORTFOLIOTB.portfoliono,9,1) in ('5', '6','8') --2010-09-24 Roger Seto Fix to include PBD portfolios--HH20141114 Commented
AND substring(hitrust..MXPORTFOLIOTB.portfoliono,9,1) in ('5', '6','8','0')--HH20141114 Add Type 0 
AND rtrim(isnull(hitrust.dbo.MXCTRACTTB.REFERENCE,'')) in ('CASH','STOCK')   
AND HITRUST..MXUNITCLASSTB.DELETED = 0 /*GW 20051007 UNITCLASS*/
--AND (hitrust.dbo.MXUNITCLASSTB.CLASSCODE = '1N'      -- Note
--OR hitrust.dbo.MXUNITCLASSTB.CLASSCODE = '1B')      -- Bone
AND hitrust.dbo.MXUNITCLASSTB.CLASSCODE like '1%'


/*
-- BC081105 begin
and hitrust..MXFUNDTB.fundkey not in 
	(select	case @company
		when 'DSBL'	then fundkeydsb
		when 'MVBL'	then fundkeymvb
		----BCM13016_099 - 2014-01-14----
		when 'BCML'	then fundkeybcm
		else	-1	-- for OTHER
		----BCM13016_099 - 2014-01-14----
		end
	from	tb_lehman
	where	zeropriced = 'Y')
and hitrust..MXFUNDTB.fundkey not in 
	(select	case @company
		when 'DSBL'	then fundkeydsb
		when 'MVBL'	then fundkeymvb
		----BCM13016_099 - 2014-01-14----
		when 'BCML'	then fundkeybcm
		else	-1	-- for OTHER
		----BCM13016_099 - 2014-01-14----
		end
	from	tb_octave
	where	zeropriced = 'Y')
-- BC081105 end
/* Thomas 20120216 Start */
--and hitrust..MXCOUNTRYTB.countryiso = 'HM'
/* Thomas 20120216 End */
-------------------------------------------
--order by hitrust..MXCTRACTTB.SSREF
--Added by louie 2007/06/27
*/

order by hitrust..MXPORTFOLIOTB.portfoliono , hitrust..MXCTRACTTB.CTRACTNO
--End 


END











--EXEC SP_RedemptionConfirmation 'BCML','ALL','2014/01/13','2014/01/14','ALL'
/*
SELECT * FROM bcmdb.dbo.TB_BOND_PYMT_TXN 



SELECT * FROM bcmdb.dbo.TB_BOND_PYMT_TXN  TB_BONDTXN_B 
JOIN hitrust..MXPORTFOLIOTB		ON TB_BONDTXN_B.PORTFOLIOKEY = hitrust..MXPORTFOLIOTB.PORTFOLIOKEY 
JOIN hitrust..MXFUNDTB		ON TB_BONDTXN_B.FUNDKEY = hitrust..MXFUNDTB.FUNDKEY
WHERE
	TB_BONDTXN_B.COUPON_PYMT_DATE = '2014/01/14'                                                             

SELECT LEFT(VW_SECURITY.METHOD,20) + '  (SHARES)' 
FROM VW_UDF_REDEEM_SECURITY AS VW_SECURITY

*/



GO


