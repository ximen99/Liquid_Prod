
SET NOCOUNT ON
DECLARE @SQL VARCHAR(MAX)
SET @SQL = '
use RMRepository
drop table if exists #collapsedLegs
;

;with doubleFloat
as
(select PositionParentId 
 from 
 rmstg.allSource_enriched
 where ISR_streamName LIKE ''%IRS''
and SwapLegTypeCode   = ''FLOAT_LEG''
group by PositionParentId 
having COUNT(*) >1)
,
FltLeg AS
(
SELECT * , iif(SharesOrParValue >= 0 , ''Rec'', ''Pay'') PayOrRec
FROM [rmstg].[AllSource_Enriched]
WHERE ISR_streamName LIKE ''%IRS''
AND SwapLegTypeCode   = ''FLOAT_LEG''
  and PositionParentId in (select PositionParentId   from doubleFloat)
  and SharesOrParValue >= 0
 )
,FixLeg as
(
SELECT * ,iif(SharesOrParValue >= 0 , ''Rec'', ''Pay'') PayOrRec
FROM [rmstg].[AllSource_Enriched]
WHERE ISR_streamName LIKE ''%IRS''
--AND SwapLegTypeCode   = ''FIXED_LEG''
  and SharesOrParValue < 0
   and PositionParentId in (select PositionParentId   from doubleFloat)
 )
 ,
 collapsedLegs
 as
 (
SELECT

FixLeg.SecId + ''_'' + FltLeg.SecId as  CombinedSecId,
FixLeg.SecId + ''_'' + FltLeg.SecId CombinedPositionId,
FixLeg.SecIdParent CombinedPositionParentId,
FixLeg.securityName + ''/'' + FltLeg.securityName CombinedSecurityName,
FixLeg.*,
iif(FixLeg.PayOrRec = ''Pay'',   FixLeg.ResetSpread,FltLeg.ResetSpread) as ResetSpreadPay,

-----RM_Reference.RMFormatFrequency( 
	iif(FixLeg.PayOrRec = ''Pay'', FltLeg.couponFrequencyCode , FixLeg.couponFrequencyCode) --) 
		as  CouponFrequencyRec,
iif(FixLeg.PayOrRec = ''Pay'',   FixLeg.CouponRate ,FltLeg.CouponRate) as CouponRatePay,
iif(FixLeg.PayOrRec = ''Pay'',   FltLeg.CouponRate,FixLeg.CouponRate) as CouponRateRec,
-----RM_Reference.RMFormatDaycount( 
	iif(FixLeg.PayOrRec = ''Pay'',    FltLeg.DayCountBasis,FixLeg.DayCountBasis) --)  
		as DayCountBasisRec,
-----RM_Reference.RMFormatCurve( 
	iif(FixLeg.PayOrRec = ''Pay'',  FltLeg.referenceCurve , FixLeg.referenceCurve) --) 
		as ReferenceRateCurveRec,

CASE iif(FixLeg.PayOrRec = ''Pay'',    FltLeg.ReferenceRateTerm , FixLeg.ReferenceRateTerm)
WHEN 
	''1D'' THEN ''daily'' WHEN ''1M'' THEN ''monthly'' WHEN ''2M'' THEN ''bimonthly'' WHEN ''3M'' THEN ''quarterly'' WHEN NULL THEN ''''
   ELSE iif(FixLeg.PayOrRec = ''Pay'',    FltLeg.ReferenceRateTerm , FixLeg.ReferenceRateTerm)
END  as ReferenceRateTermRec,

---RM_Reference.RMFormatFrequency( 
	iif(FixLeg.PayOrRec = ''Pay'', FltLeg.ResetFrequency,   FixLeg.ResetFrequency) --) 
		as  ResetRateFrequencyRec,
iif(FixLeg.PayOrRec = ''Pay'',   FltLeg.ResetSpread, FixLeg.ResetSpread)  as ResetSpreadRec,
iif(FixLeg.PayOrRec = ''Pay'',   FltLeg.LocalTotalMarketValue, FixLeg.LocalTotalMarketValue)  as LocalTotalMarketValueRec,
iif(FixLeg.PayOrRec = ''Pay'',   FltLeg.[BaseTotalMarketValue],FixLeg.[BaseTotalMarketValue]) as BaseTotalMarketValueRec,
----RM_Reference.RMFormatFrequency( 
	iif(FixLeg.PayOrRec = ''Rec'', FltLeg.couponFrequencyCode , FixLeg.couponFrequencyCode) --) 
		as  CouponFrequencyPay,
----RM_Reference.RMFormatDaycount( 
	iif(FixLeg.PayOrRec = ''Rec'',    FltLeg.DayCountBasis,FixLeg.DayCountBasis) --)  
	as DayCountBasisPay,
---RM_Reference.RMFormatCurve(
	iif(FixLeg.PayOrRec = ''Rec'',   FltLeg.referenceCurve , FixLeg.referenceCurve)--)  
	as ReferenceRateCurvePay,
CASE iif(FixLeg.PayOrRec = ''Rec'',    FltLeg.ReferenceRateTerm , FixLeg.ReferenceRateTerm)
WHEN 
	''1D'' THEN ''daily'' WHEN ''1M'' THEN ''monthly'' WHEN ''2M'' THEN ''bimonthly'' WHEN ''3M'' THEN ''quarterly'' WHEN NULL THEN ''''
	ELSE iif(FixLeg.PayOrRec = ''Rec'',    FltLeg.ReferenceRateTerm , FixLeg.ReferenceRateTerm)
END  as ReferenceRateTermPay,

----RM_Reference.RMFormatFrequency( 
	iif(FixLeg.PayOrRec = ''Rec'', FltLeg.ResetFrequency,   FixLeg.ResetFrequency)--) 
	as  ResetRateFrequencyPay,

iif(FixLeg.PayOrRec = ''Rec'',   FltLeg.LocalTotalMarketValue, FixLeg.LocalTotalMarketValue)  as LocalTotalMarketValuePay,
iif(FixLeg.PayOrRec = ''Rec'',   FltLeg.[BaseTotalMarketValue],FixLeg.[BaseTotalMarketValue]) as BaseTotalMarketValuePay,
iif(FixLeg.PayOrRec = ''Pay'',   FixLeg.Currency,FltLeg.Currency) AS CurrencyCodePay,
iif(FixLeg.PayOrRec = ''Rec'',   FixLeg.Currency,FltLeg.Currency) AS CurrencyCodeRec,

 

iif(FixLeg.PayOrRec = ''Pay'',   FixLeg.SharesOrParValue,FltLeg.SharesOrParValue) AS PayNotional,     
iif(FixLeg.PayOrRec = ''Rec'',   FixLeg.SharesOrParValue,FltLeg.SharesOrParValue)  AS RecNotional,

 

iif(FixLeg.PayOrRec = ''Pay'',   FixLeg.PurchaseDate, FltLeg.PurchaseDate) as PurchaseDatePay,    
iif(FixLeg.PayOrRec = ''Pay'',   FltLeg.PurchaseDate,FixLeg.PurchaseDate) as PurchaseDateRec,    

 

iif(FixLeg.PayOrRec = ''Pay'',   FixLeg.SwapLegTypeCode, FltLeg.SwapLegTypeCode) as SwapLegTypeCodePay,  
iif(FixLeg.PayOrRec = ''Pay'',   FltLeg.SwapLegTypeCode, FixLeg.SwapLegTypeCode) as SwapLegTypeCodeRec,

 ((FixLeg.DirtyValueTotalQC + FltLeg.DirtyValueTotalQC) / nullif(FltLeg.SharesOrParValue,0)) AS LocalMarketPrice_Override            -- CM 20191203

 

FROM FixLeg /* Pay leg */
JOIN  FltLeg    /* Rec Leg */ 
    ON   (    FixLeg.SecIdParent = FltLeg.SecIdParent   )
WHERE 
FixLeg.ISR_streamName = FltLeg.ISR_streamName            
AND FixLeg.ISR_streamName LIKE ''%IRS''
)

select * into #collapsedLegs
from collapsedLegs;

--create temp allSourceModelled with all cols
drop table if exists #allSourceModelled;
select top 1000 * 
into #allSourceModelled
from rmstg.AllSource_Modelled;

delete from #allSourceModelled;

--------------------------------------

Insert  into #allSourceModelled
(	RiskDate
,	SourceSystem
,	ISR_streamName
,	ExcludeOverride
,	ModelExceptionOverride

,	Currency
,	FxUnderlyingCcyCode
,	LocalPriceCcyCode
,	PriceCcyCode
,	QuoteCcyCode
,	SettlementCcyCode
,	AccountingSystemAssetClass
,	AssetClass
,	assetClassCode
,	instrumentGroupCode
,	InstrumentTypeCode
,	InstrumentTypeDesc
,	InvestmentType
,	OptionType
,	SwapLegTypeCode
,	FwdLegTypeCode
,	ExpiryDate
,	ForwardDate
,	IssueDate
,	MaturityDate
,	ValuationDate

,	ConstituentHoldingGroupName
,	PortfolioCode
,	PortfolioObjectiveCode
,	AccountingSystemSecId
,	AssetId
,	ExchangeId_CUSIP 
,	ExchangeId_ISIN
,	ExchangeCode
,	ExchangeId_RIC
,	ExchangeId_SEDOL
,	ExchangeId_Ticker
,	PositionId
,	PositionName
,	PositionParentId
,	SecId
,	SecIdParent
,	securityName
,	securityNameParent
,	SwapName
,	HasLookthrough
,	IsLookthroughConstituent
,	LookThroughNameConstituents
,	LookthroughScalingMethod
,	ParentOrConstituent
,	PersistOrCollapse

,	BusinessDayRule
,	CompoundingFrequencyCode
,	ConstantTerm
,	CounterParty
,	couponFrequencyCode
,	CouponRate
,	CouponType
,	DayCountBasis
,	GicsCodeLowestLevel
,	IssuerCode
,	IssuerName
,	IsZeroCoupon
,	OptionStyle
,	PositionProxyPricedSecurityName
,	referenceCurve
,	ReferenceFrequency
,	ReferenceRateTerm
,	ResetFrequency
,	ResetSpread
,	RiskCountryCode
,	RisklessCurve
,	SecurityType
,	StrikeType
,	IssuerDriver

,	SwapIndexId
,	FloatingRateIndicator
,	OnMargin

,	CorrectLocalMarketPrice
,	EntryPrice
,	FwdPrice
,	LatestClosingMarketPrice
,	LocalMarketPrice
,	PriceInCad
,	SpotFXRate
,	StrikePrice
,	resetSpreadBP
,	ResetSpreadFI
,	ResetSpreadRec
,	ResetSpreadPay
,	Amount
,	BaseAccruedInterest
,	BaseMarketValue
,	BaseTotalMarketValue
,	ContractSize
,	CurrentRate
,	LocalAccruedInterestNative
,	LocalMarketValue
,	LocalTotalMarketValue
,	minimumRate
,	Notional
,	Quantity
,	SharesOrParValue

,	Duration
,	rptAC_001
,	rptGlb_001
,	rptPort_001
,	rptPos_001
,	rptSys_001
,	rptUncl_001
,   PortCalc
,	ParentPortfolioCode
,	ModelRuleDefault
,	ModelRuleOverride
,	ProxyIndexName
,	ProxyIndexCode
,	IssuerCurve
,	InstrumentClassCode
,	FxRateCost
,	BasePrice
,	StartDate
,	Underlying
,	PurchaseDate
,	CouponFrequencyRec
,	CouponRatePay
,	CouponRateRec

,	DayCountBasisRec
,	ReferenceRateCurveRec
,	ReferenceRateTermRec
,	ResetRateFrequencyRec

,	LocalTotalMarketValueRec
,	BaseTotalMarketValueRec
,	CouponFrequencyPay
,	DayCountBasisPay
,	ReferenceRateCurvePay
,	ReferenceRateTermPay
,	ResetRateFrequencyPay
,	LocalTotalMarketValuePay
,	BaseTotalMarketValuePay

,	CurrencyCodePay
,	CurrencyCodeRec

,	PayNotional
,   RecNotional
, SubPortfolioCode    
	, BCIUltimateParentIssuerName   
, BCIGicsSector
, InstrumentClass
, InstrumentGroup
, InstrumentType
, PortfolioName 
, PurchaseDateRec   
, PurchaseDatePay  
, SwapLegTypeCodePay  
, SwapLegTypeCodeRec   
, RowChecksum 
)

select 


RiskDate
,	SourceSystem
,	ISR_streamName
,	ExcludeOverride
,	ModelExceptionOverride

,	Currency
,	FxUnderlyingCcyCode
,	LocalPriceCcyCode
,	PriceCcyCode
,	QuoteCcyCode
,	SettlementCcyCode
,	AccountingSystemAssetClass
,	AssetClass
,	assetClassCode
,	instrumentGroupCode
,	InstrumentTypeCode
,	InstrumentTypeDesc
,	InvestmentType
,	OptionType
,	SwapLegTypeCode
,	FwdLegTypeCode
,	ExpiryDate
,	ForwardDate
,	IssueDate
,	MaturityDate
,	ValuationDate

,	ConstituentHoldingGroupName
,	PortfolioCode
,	PortfolioObjectiveCode
,	AccountingSystemSecId
,	AssetId
,	ExchangeId_CUSIP 
,	ExchangeId_ISIN
,	ExchangeCode
,	ExchangeId_RIC
,	ExchangeId_SEDOL
,	ExchangeId_Ticker
,	CombinedPositionId PositionId
,	PositionName
,	CombinedPositionParentId PositionParentId
,	CombinedSecId SecId
,	SecIdParent
,	CombinedSecurityName SecurityName
,	SecurityNameParent
,	SwapName
,	HasLookthrough
,	IsLookthroughConstituent
,	LookThroughNameConstituents
,	LookthroughScalingMethod
,	ParentOrConstituent
,	PersistOrCollapse

,	BusinessDayRule
,	CompoundingFrequencyCode
,	ConstantTerm
,	CounterParty
,	couponFrequencyCode
,	CouponRate
,	CouponType
,	DayCountBasis
,	GicsCodeLowestLevel
,	IssuerCode
,	IssuerName
,	IsZeroCoupon
,	OptionStyle
,	PositionProxyPricedSecurityName
,	referenceCurve
,	ReferenceFrequency
,	ReferenceRateTerm
,	ResetFrequency
,	null ResetSpread 
,	RiskCountryCode
,	RisklessCurve
,	SecurityType
,	StrikeType
,	IssuerDriver

,	SwapIndexId
,	FloatingRateIndicator
,	OnMargin
,	CorrectLocalMarketPrice
,	EntryPrice
,	FwdPrice
,	LatestClosingMarketPrice
,	LocalMarketPrice_Override as LocalMarketPrice
,	PriceInCad
,	SpotFXRate
,	StrikePrice
,	resetSpreadBP
,	ResetSpreadFI
,	ResetSpreadRec
,	ResetSpreadPay   
,	Amount
,	BaseAccruedInterest
,	BaseMarketValue
,	BaseTotalMarketValue
,	ContractSize
,	CurrentRate
,	LocalAccruedInterestNative
,	LocalMarketValue
,	LocalTotalMarketValue
,	minimumRate
,	Notional
,	Quantity
,	SharesOrParValue

,	Duration
,	rptAC_001
,	rptGlb_001
,	rptPort_001
,	rptPos_001
,	rptSys_001
,	rptUncl_001
,   PortCalc
,	ParentPortfolioCode
,	ModelRuleDefault
,	ModelRuleOverride
,	ProxyIndexName
,	ProxyIndexCode
,	IssuerCurve
,	InstrumentClassCode
,	FxRateCost
,	BasePrice
,	StartDate
,	Underlying
,	PurchaseDate
,	CouponFrequencyRec
,	CouponRatePay
,	CouponRateRec

,	DayCountBasisRec
,	ReferenceRateCurveRec
,	ReferenceRateTermRec
,	ResetRateFrequencyRec
,	LocalTotalMarketValueRec
,	BaseTotalMarketValueRec
,	CouponFrequencyPay
,	DayCountBasisPay
,	ReferenceRateCurvePay
,	ReferenceRateTermPay
,	ResetRateFrequencyPay
,	LocalTotalMarketValuePay
,	BaseTotalMarketValuePay

,	CurrencyCodePay
,	CurrencyCodeRec

,	PayNotional
,   RecNotional
, SubPortfolioCode   
	, BCIUltimateParentIssuerName   
, BCIGicsSector
, InstrumentClass
, InstrumentGroup
, InstrumentType
, PortfolioName 
, PurchaseDateRec      
, PurchaseDatePay      
, SwapLegTypeCodePay  
, SwapLegTypeCodeRec    
, ROW_NUMBER() OVER (PARTITION BY PositionId ORDER BY PositionId ) as PositionInstance
from 
 #collapsedLegs;



update 
#allSourceModelled

SET ModelRuleOverride
    =(case when (InstrumentTypeCode = ''IR_VANILLA_SWP'' and SwapLegTypeCodePay  = ''FIXED_LEG'') then         ''RSM_InterestRateSwap_ReceiveFloatPayFixed''
                     when (InstrumentTypeCode = ''IR_CROSS_CRNCY_SWP'' and SwapLegTypeCodePay  = ''FIXED_LEG'') then ''RSM_CrossCurrencyReceiveFloatPayFixed''
                     when  (InstrumentTypeCode = ''IR_CROSS_CRNCY_SWP'' and SwapLegTypeCodeRec  = ''FIXED_LEG'') then ''RSM_CrossCurrencyPayFloatReceiveFixed''
                     when (InstrumentTypeCode = ''IR_OVERNIGHT_IDX_SWP'' and SwapLegTypeCodePay  = ''FIXED_LEG'') then ''OISM_ReceiveFloatPayFixed''
                     when  (InstrumentTypeCode = ''IR_OVERNIGHT_IDX_SWP'' and SwapLegTypeCodeRec  = ''FIXED_LEG'') then ''OISM_PayFloatReceiveFixed''
                     else ''RSM_InterestRateSwap_PayFloatReceiveFixed''       
                     end)
       where ISR_streamName in (''SCD_IRS'') ;  



UPDATE 
#allSourceModelled
 
 SET LocalTotalMarketValue = LocalTotalMarketValuePay + LocalTotalMarketValueRec
	where ISR_streamName in (''SCD_IRS'', ''SCD_FXFWD'') ;  

	UPDATE 
#allSourceModelled
 
 SET BaseTotalMarketValue  = BaseTotalMarketValuePay  + BaseTotalMarketValueRec
	where ISR_streamName in (''SCD_IRS'', ''SCD_FXFWD'') ; 

	UPDATE 
#allSourceModelled
 
 SET LocalTotalMarketValue = LocalTotalMarketValuePay + LocalTotalMarketValueRec
	where ISR_streamName in (''SCD_IRS'', ''SCD_FXFWD'') ;  


	
UPDATE 
#allSourceModelled

 SET Amount
    = (case when RecNotional > 0 then RecNotional
			else PayNotional end)
	where InstrumentTypeCode in (''IR_VANILLA_SWP'', ''IR_OVERNIGHT_IDX_SWP'')  ; 

--	select * from #allSourceModelled



--update for [RM_Reference].[RMFormatFrequency]

--select CouponFrequencyPay,CouponFrequencyRec,ReferenceFrequency,ResetRateFrequencyPay,ResetRateFrequencyRec from #allSourceModelled

update #allSourceModelled
set CouponFrequencyPay = CASE isnull(CouponFrequencyPay, ''NULL'')
    WHEN ''A'' THEN ''annual''
    WHEN ''S'' THEN ''semiannual''	
    WHEN ''Q'' THEN ''quarterly'' 
    WHEN ''M'' THEN ''monthly''  

	WHEN ''1M'' THEN ''monthly''
	WHEN ''1Y'' THEN ''annual''
	WHEN ''2M'' THEN ''bimonthly''
	WHEN ''3M'' THEN ''quarterly''
	WHEN ''4M'' THEN ''four-monthly''
	WHEN ''6M'' THEN ''semiannual''

	-- For Ares, which gives the number of payments per year, rather than the frequency
	WHEN ''1''  THEN ''annual''
	WHEN ''2''  THEN ''semiannual''
	WHEN ''4''  THEN ''quarterly''
	WHEN ''6''  THEN ''bimonthly''
	WHEN ''12'' THEN ''monthly''
	WHEN ''52'' THEN ''weekly''

    ELSE iif( CouponFrequencyPay in ( ''annual'',''semiannual'' , ''quarterly'' , ''bimonthly'', ''monthly'' , ''weekly'', ''daily'', ''UNK'' ) , CouponFrequencyPay, ''UNK'')
END,
CouponFrequencyRec = CASE isnull(CouponFrequencyRec, ''NULL'')
    WHEN ''A'' THEN ''annual''
    WHEN ''S'' THEN ''semiannual''	
    WHEN ''Q'' THEN ''quarterly'' 
    WHEN ''M'' THEN ''monthly''  

	WHEN ''1M'' THEN ''monthly''
	WHEN ''1Y'' THEN ''annual''
	WHEN ''2M'' THEN ''bimonthly''
	WHEN ''3M'' THEN ''quarterly''
	WHEN ''4M'' THEN ''four-monthly''
	WHEN ''6M'' THEN ''semiannual''

	-- For Ares, which gives the number of payments per year, rather than the frequency
	WHEN ''1''  THEN ''annual''
	WHEN ''2''  THEN ''semiannual''
	WHEN ''4''  THEN ''quarterly''
	WHEN ''6''  THEN ''bimonthly''
	WHEN ''12'' THEN ''monthly''
	WHEN ''52'' THEN ''weekly''

    ELSE iif( CouponFrequencyRec in ( ''annual'',''semiannual'' , ''quarterly'' , ''bimonthly'', ''monthly'' , ''weekly'', ''daily'', ''UNK'' ) , CouponFrequencyRec, ''UNK'')
END,
ResetRateFrequencyPay = CASE isnull(ResetRateFrequencyPay, ''NULL'')
    WHEN ''A'' THEN ''annual''
    WHEN ''S'' THEN ''semiannual''	
    WHEN ''Q'' THEN ''quarterly'' 
    WHEN ''M'' THEN ''monthly''  

	WHEN ''1M'' THEN ''monthly''
	WHEN ''1Y'' THEN ''annual''
	WHEN ''2M'' THEN ''bimonthly''
	WHEN ''3M'' THEN ''quarterly''
	WHEN ''4M'' THEN ''four-monthly''
	WHEN ''6M'' THEN ''semiannual''

	-- For Ares, which gives the number of payments per year, rather than the frequency
	WHEN ''1''  THEN ''annual''
	WHEN ''2''  THEN ''semiannual''
	WHEN ''4''  THEN ''quarterly''
	WHEN ''6''  THEN ''bimonthly''
	WHEN ''12'' THEN ''monthly''
	WHEN ''52'' THEN ''weekly''

    ELSE iif( ResetRateFrequencyPay in ( ''annual'',''semiannual'' , ''quarterly'' , ''bimonthly'', ''monthly'' , ''weekly'', ''daily'', ''UNK'' ) , ResetRateFrequencyPay, ''UNK'')
END,
ResetRateFrequencyRec= CASE isnull(ResetRateFrequencyRec, ''NULL'')
    WHEN ''A'' THEN ''annual''
    WHEN ''S'' THEN ''semiannual''	
    WHEN ''Q'' THEN ''quarterly'' 
    WHEN ''M'' THEN ''monthly''  

	WHEN ''1M'' THEN ''monthly''
	WHEN ''1Y'' THEN ''annual''
	WHEN ''2M'' THEN ''bimonthly''
	WHEN ''3M'' THEN ''quarterly''
	WHEN ''4M'' THEN ''four-monthly''
	WHEN ''6M'' THEN ''semiannual''

	-- For Ares, which gives the number of payments per year, rather than the frequency
	WHEN ''1''  THEN ''annual''
	WHEN ''2''  THEN ''semiannual''
	WHEN ''4''  THEN ''quarterly''
	WHEN ''6''  THEN ''bimonthly''
	WHEN ''12'' THEN ''monthly''
	WHEN ''52'' THEN ''weekly''

    ELSE iif( ResetRateFrequencyRec in ( ''annual'',''semiannual'' , ''quarterly'' , ''bimonthly'', ''monthly'' , ''weekly'', ''daily'', ''UNK'' ) , ResetRateFrequencyRec, ''UNK'')
END


--update [RMFormatDaycount]



update #allSourceModelled
set 
DayCountBasisPay =
CASE DayCountBasisPay
WHEN ''30/360'' THEN ''dayCount_30_360''
WHEN ''30/365'' THEN ''dayCount_30_365''
WHEN  ''ACT/360'' THEN ''dayCount_Act_360''
WHEN  ''ACT/ACT'' THEN ''dayCount_Act_Act''
WHEN  ''ACT/365'' THEN ''dayCount_Act_365''
WHEN  ''30E/360'' THEN ''dayCount_30E_360''
WHEN  ''ACT/ACT_ISMA'' THEN ''dayCount_Act_Act''
ELSE DayCountBasisPay
END

,
DayCountBasisRec =
CASE DayCountBasisRec
WHEN ''30/360'' THEN ''dayCount_30_360''
WHEN ''30/365'' THEN ''dayCount_30_365''
WHEN  ''ACT/360'' THEN ''dayCount_Act_360''
WHEN  ''ACT/ACT'' THEN ''dayCount_Act_Act''
WHEN  ''ACT/365'' THEN ''dayCount_Act_365''
WHEN  ''30E/360'' THEN ''dayCount_30E_360''
WHEN  ''ACT/ACT_ISMA'' THEN ''dayCount_Act_Act''
ELSE DayCountBasisRec
END



--update curve format
update #allSourceModelled
set ReferenceRateCurvePay
 =
    CASE		 WHEN ReferenceRateCurvePay IN (''USD LIBOR'', ''USLIBOR'') THEN ''USD Swap - LIBOR''
				 WHEN ReferenceRateCurvePay = ''CAD Swap'' and ReferenceRateTermPay=''daily'' THEN ''CAD CORRA OIS (SP)''		-- Change in MSCI RM
						
			 WHEN ReferenceRateCurvePay = ''CDOR'' THEN ''CAD Swap''
			 WHEN ReferenceRateCurvePay = ''CORRA'' THEN ''CAD CORRA OIS (SP)''		-- Change in MSCI RM
			 WHEN ReferenceRateCurvePay IS NULL THEN ''''
			 ELSE ReferenceRateCurvePay
    END
	,
	ReferenceRateCurveRec =
    CASE		 WHEN ReferenceRateCurveRec IN (''USD LIBOR'', ''USLIBOR'') THEN ''USD Swap - LIBOR''		
					 WHEN ReferenceRateCurveRec = ''CAD Swap'' and ReferenceRateTermRec=''daily'' THEN ''CAD CORRA OIS (SP)''		-- Change in MSCI RM
				
			 WHEN ReferenceRateCurveRec = ''CDOR'' THEN ''CAD Swap''
			 WHEN ReferenceRateCurveRec = ''CORRA'' THEN ''CAD CORRA OIS (SP)''		-- Change in MSCI RM
			 WHEN ReferenceRateCurveRec IS NULL THEN ''''
			 ELSE ReferenceRateCurveRec
    END


--apply final updates
----------------------------------------------------------


--Derive best Exchange traded Id for model
-- This will recognize any override id''s previously applied

UPDATE
#allSourceModelled

 SET  ExchangeId_Best = ( SELECT  BestExchangeIdentifier
						  FROM  [RM_Reference].getBestExchangeIdentifier(COALESCE([ModelRuleOverride],[ModelRuleDefault])
																				 ,ExchangeId_CUSIP  
																				 ,ExchangeId_ISIN  
																				 ,ExchangeId_RIC  
																				 ,ExchangeId_SEDOL 
																				 ,ExchangeId_Ticker  
																				 , ISR_streamName
																				 ,AccountingSystemSecId
																		) 
						)
	, ExchangeId_BestType = ( SELECT  BestExchangeIdentifierType
							FROM  [RM_Reference].getBestExchangeIdentifier(COALESCE([ModelRuleOverride],[ModelRuleDefault])
																					,ExchangeId_CUSIP  
																					,ExchangeId_ISIN  
																					,ExchangeId_RIC  
																					,ExchangeId_SEDOL 
																					,ExchangeId_Ticker 
																					,ISR_streamName
																					,AccountingSystemSecId
																			) 
							)


UPDATE 
 #allSourceModelled

 SET  CalculatedAccruedInterest =
 CASE 
WHEN isnull(Amount ,0 ) = 0  THEN NULL

ELSE  (LocalAccruedInterestNative * CAST(100 AS float) / Amount) 

END 



 


UPDATE 
 #allSourceModelled

 SET latestClosingMarketPrice = 
 CASE 
WHEN isnull(Amount ,0) = 0  THEN NULL   -- shirley fixed 2019/12/04

ELSE 
(CASE WHEN  ISNULL( modelRuleOverride, ModelRuleDefault   ) in (''RSM_InterestRateSwap_ReceiveFloatPayFixed'', ''RSM_InterestRateSwap_PayFloatReceiveFixed'') 
			THEN (LocalTotalMarketValue  /nullif( Amount,0))
      WHEN ISNULL( modelRuleOverride, ModelRuleDefault   ) in (''RSM_CrossCurrencyReceiveFloatPayFixed'', ''RSM_CrossCurrencyPayFloatReceiveFixed'') 
			THEN LocalTotalMarketValue 
      WHEN ISNULL( modelRuleOverride, ModelRuleDefault   ) in (''OISM_OISReceiveFloatPayFixed'', ''OISM_OISPayFloatReceiveFixed'',''OISM_ReceiveFloatPayFixed'', ''OISM_PayFloatReceiveFixed'') 
			THEN ((LocalTotalMarketValue *100) / nullif(Amount,0) )
      WHEN ISNULL( modelRuleOverride, ModelRuleDefault   ) in (''GSM_MortgageBackedSecurity'', ''GBM_AssetBackSecurity'')
			THEN (LocalTotalMarketValue  /nullif( Amount,0) )
	  WHEN ISNULL( modelRuleOverride, ModelRuleDefault   ) IN (''ETM_Loan'',''BLM_BankLoanProxy'') AND ISR_streamName NOT IN (''Ares'', ''SCD_Minke'', ''SCD_Beluga'')
			THEN ((LocalTotalMarketValue + ISNULL(LocalAccruedInterestNative,0)) * 100 / nullif( Amount,0))
	  WHEN ISNULL( modelRuleOverride, ModelRuleDefault   ) IN (''ETM_Loan'',''BLM_BankLoanProxy'') AND ISR_streamName IN (''Ares'', ''SCD_Minke'', ''SCD_Beluga'')
			THEN ((LocalTotalMarketValue) * 100 / nullif( Amount,0))
      ELSE
			abs((LocalTotalMarketValue / nullif( Amount,0)))*100
       END)

END

 WHERE ISR_streamName NOT IN (''Cowen'', ''EOS'')  ;


 ------------------
 --Reformat to RM :
 ------------------
UPDATE
 #allSourceModelled
 SET  referenceCurve =  
    CASE		 WHEN referenceCurve IN (''USD LIBOR'', ''USLIBOR'') THEN ''USD Swap - LIBOR''		
				 WHEN referenceCurve = ''CDOR'' and ReferenceRateTerm=''1D''  THEN ''CAD CORRA OIS (SP)''
				
			 WHEN referenceCurve = ''CDOR'' THEN ''CAD Swap''
			 WHEN referenceCurve = ''CORRA'' THEN ''CAD CORRA OIS (SP)''		-- Change in MSCI RM
			 WHEN referenceCurve IS NULL THEN ''''
			 ELSE referenceCurve
    END 
 WHERE referenceCurve <> ''US Prime Rate'';		-- Don''t overwrite cases of Prime rate set in Antares view

 --DayCountBasis  (function will pass through already formated dayCount values)
 
UPDATE
 #allSourceModelled
 SET  #allSourceModelled.DayCountBasis =  
  
CASE DayCountBasis
WHEN ''30/360'' THEN ''dayCount_30_360''
WHEN ''30/365'' THEN ''dayCount_30_365''
WHEN  ''ACT/360'' THEN ''dayCount_Act_360''
WHEN  ''ACT/ACT'' THEN ''dayCount_Act_Act''
WHEN  ''ACT/365'' THEN ''dayCount_Act_365''
WHEN  ''30E/360'' THEN ''dayCount_30E_360''
WHEN  ''ACT/ACT_ISMA'' THEN ''dayCount_Act_Act''
ELSE DayCountBasis
END

UPDATE 
 #allSourceModelled
 SET RisklessCurve =  
 CASE 
    WHEN LocalPriceCcyCode IS NULL THEN NULL
	WHEN LocalPriceCcyCode IN (''ARS'',''BRL'',''CLP'',''CNH'',''CNY'',''COP'',''EGP'',''IDR'',''ILS'',''LKR'',''NGN'',''PEN'',''RON'',''RUB'',''TRY'',''UYU'') THEN LocalPriceCcyCode + '' Govt (NS)''
    ELSE LocalPriceCcyCode + '' Govt'' END


UPDATE 
 #allSourceModelled
  SET  YieldRiskFactorTerm = 
CASE WHEN Duration  IS null
THEN null

ELSE CAST(round(Duration,0) AS varchar(50))+''Y'' 
END 
 
 
UPDATE 
 #allSourceModelled
 SET  couponFrequencyCode = 
 CASE isnull(couponFrequencyCode, ''NULL'')
    WHEN ''A'' THEN ''annual''
    WHEN ''S'' THEN ''semiannual''	
    WHEN ''Q'' THEN ''quarterly'' 
    WHEN ''M'' THEN ''monthly''  

	WHEN ''1M'' THEN ''monthly''
	WHEN ''1Y'' THEN ''annual''
	WHEN ''2M'' THEN ''bimonthly''
	WHEN ''3M'' THEN ''quarterly''
	WHEN ''4M'' THEN ''four-monthly''
	WHEN ''6M'' THEN ''semiannual''

	-- For Ares, which gives the number of payments per year, rather than the frequency
	WHEN ''1''  THEN ''annual''
	WHEN ''2''  THEN ''semiannual''
	WHEN ''4''  THEN ''quarterly''
	WHEN ''6''  THEN ''bimonthly''
	WHEN ''12'' THEN ''monthly''
	WHEN ''52'' THEN ''weekly''

    ELSE iif( couponFrequencyCode in ( ''annual'',''semiannual'' , ''quarterly'' , ''bimonthly'', ''monthly'' , ''weekly'', ''daily'', ''UNK'' ) , couponFrequencyCode, ''UNK'')
	END;

UPDATE #allSourceModelled
SET CompoundingFrequencyCode = CASE isnull(CompoundingFrequencyCode, ''NULL'')
    WHEN ''A'' THEN ''annual''
    WHEN ''S'' THEN ''semiannual''	
    WHEN ''Q'' THEN ''quarterly'' 
    WHEN ''M'' THEN ''monthly''  

	WHEN ''1M'' THEN ''monthly''
	WHEN ''1Y'' THEN ''annual''
	WHEN ''2M'' THEN ''bimonthly''
	WHEN ''3M'' THEN ''quarterly''
	WHEN ''4M'' THEN ''four-monthly''
	WHEN ''6M'' THEN ''semiannual''

	-- For Ares, which gives the number of payments per year, rather than the frequency
	WHEN ''1''  THEN ''annual''
	WHEN ''2''  THEN ''semiannual''
	WHEN ''4''  THEN ''quarterly''
	WHEN ''6''  THEN ''bimonthly''
	WHEN ''12'' THEN ''monthly''
	WHEN ''52'' THEN ''weekly''

    ELSE iif( CompoundingFrequencyCode in ( ''annual'',''semiannual'' , ''quarterly'' , ''bimonthly'', ''monthly'' , ''weekly'', ''daily'', ''UNK'' ) , CompoundingFrequencyCode, ''UNK'')
	END;


UPDATE #allSourceModelled
SET ResetFrequency = CASE isnull(ResetFrequency, ''NULL'')
    WHEN ''A'' THEN ''annual''
    WHEN ''S'' THEN ''semiannual''	
    WHEN ''Q'' THEN ''quarterly'' 
    WHEN ''M'' THEN ''monthly''  

	WHEN ''1M'' THEN ''monthly''
	WHEN ''1Y'' THEN ''annual''
	WHEN ''2M'' THEN ''bimonthly''
	WHEN ''3M'' THEN ''quarterly''
	WHEN ''4M'' THEN ''four-monthly''
	WHEN ''6M'' THEN ''semiannual''

	-- For Ares, which gives the number of payments per year, rather than the frequency
	WHEN ''1''  THEN ''annual''
	WHEN ''2''  THEN ''semiannual''
	WHEN ''4''  THEN ''quarterly''
	WHEN ''6''  THEN ''bimonthly''
	WHEN ''12'' THEN ''monthly''
	WHEN ''52'' THEN ''weekly''

    ELSE iif( ResetFrequency in ( ''annual'',''semiannual'' , ''quarterly'' , ''bimonthly'', ''monthly'' , ''weekly'', ''daily'', ''UNK'' ) , ResetFrequency, ''UNK'')
	END;

UPDATE #allSourceModelled
SET ReferenceFrequency = CASE isnull(ReferenceFrequency, ''NULL'')
    WHEN ''A'' THEN ''annual''
    WHEN ''S'' THEN ''semiannual''	
    WHEN ''Q'' THEN ''quarterly'' 
    WHEN ''M'' THEN ''monthly''  

	WHEN ''1M'' THEN ''monthly''
	WHEN ''1Y'' THEN ''annual''
	WHEN ''2M'' THEN ''bimonthly''
	WHEN ''3M'' THEN ''quarterly''
	WHEN ''4M'' THEN ''four-monthly''
	WHEN ''6M'' THEN ''semiannual''

	-- For Ares, which gives the number of payments per year, rather than the frequency
	WHEN ''1''  THEN ''annual''
	WHEN ''2''  THEN ''semiannual''
	WHEN ''4''  THEN ''quarterly''
	WHEN ''6''  THEN ''bimonthly''
	WHEN ''12'' THEN ''monthly''
	WHEN ''52'' THEN ''weekly''

    ELSE iif( ReferenceFrequency in ( ''annual'',''semiannual'' , ''quarterly'' , ''bimonthly'', ''monthly'' , ''weekly'', ''daily'', ''UNK'' ) , ReferenceFrequency, ''UNK'')
	END;

UPDATE #allSourceModelled
SET ReferenceRateTermRec = CASE isnull(ReferenceRateTermRec, ''NULL'')
    WHEN ''A'' THEN ''annual''
    WHEN ''S'' THEN ''semiannual''	
    WHEN ''Q'' THEN ''quarterly'' 
    WHEN ''M'' THEN ''monthly''  

	WHEN ''1M'' THEN ''monthly''
	WHEN ''1Y'' THEN ''annual''
	WHEN ''2M'' THEN ''bimonthly''
	WHEN ''3M'' THEN ''quarterly''
	WHEN ''4M'' THEN ''four-monthly''
	WHEN ''6M'' THEN ''semiannual''

	-- For Ares, which gives the number of payments per year, rather than the frequency
	WHEN ''1''  THEN ''annual''
	WHEN ''2''  THEN ''semiannual''
	WHEN ''4''  THEN ''quarterly''
	WHEN ''6''  THEN ''bimonthly''
	WHEN ''12'' THEN ''monthly''
	WHEN ''52'' THEN ''weekly''

    ELSE iif( ReferenceRateTermRec in ( ''annual'',''semiannual'' , ''quarterly'' , ''bimonthly'', ''monthly'' , ''weekly'', ''daily'', ''UNK'' ) , ReferenceRateTermRec, ''UNK'')
	END;


UPDATE #allSourceModelled
SET ReferenceRateTerm = CASE ReferenceRateTerm
WHEN ''1D'' THEN ''daily''
WHEN ''1M'' THEN ''monthly''
WHEN ''2M'' THEN ''bimonthly''
WHEN ''3M'' THEN ''quarterly''
WHEN NULL THEN ''''
ELSE ReferenceRateTerm
END;





;


UPDATE 
 #allSourceModelled

 SET BCIGicsSector
    = (case when isnull(ModelRuleOverride,ModelRuleDefault) = ''CASH'' then ''Cash''
                     when isnull(ModelRuleOverride,ModelRuleDefault) like (''%Repo%'') then ''Repo''
                     Else BCIGicsSector
              End); 

UPDATE 
 #allSourceModelled
 
 SET BaseTotalMarketValue = BaseTotalMarketValuePay + BaseTotalMarketValueRec
	where ISR_streamName in (''SCD_IRS'', ''SCD_FXFWD'',''SCD_CDS'')  ; 




UPDATE 
 #allSourceModelled

 SET BCIIssueDate
    = IssueDate ;  

UPDATE 
 #allSourceModelled

 SET BCIMaturityDate
    = MaturityDate ;  

UPDATE 
 #allSourceModelled

 SET BCIFXRate
    = FxRateCost ; 




update #allSourceModelled

 SET BenchmarkID
    = (select BenchmarkRD from  [RM_Reference].[getBenchmark](ParentPortfolioCode, null)) ;  



update #allSourceModelled

 SET BCIGicsSector
    = (CASE WHEN InstrumentTypeCode LIKE ''%CASH%''  
			  THEN ''Cash'' 
         WHEN InstrumentTypeCode LIKE ''%PROV%'' OR InstrumentTypeCode LIKE ''%SOVN%'' OR InstrumentTypeCode LIKE ''%MUNI%'' 
              THEN ''Government Debt'' 
         WHEN InstrumentTypeCode IN (''SHORT_TERM_REPO'', ''SELL_BUY_BACK'', ''BUY_SELL_BACK'') 
              THEN ''Repo'' 
         ELSE BCIGicsSector  
		 END); 


---------------------------
--Set  unique row Identifiers
------------------------------

/* 
Set PositionId to be unique to each row:
This should be a  unique combo, but add a sequence to each value to force uniqueness
Use Rownumber over PositionId to add a seq to positinId if duplicates
PricedSecurityName is driven off PositionId  
*/

UPDATE #allSourceModelled
SET PositionId =
		iif(PositionId LIKE (ParentPortfolioCode + ''%''),'''',ParentPortfolioCode + ''_'') 
	+ PositionId 
	
WHERE ISR_StreamName NOT LIKE ''%EBSCONST'' and ISR_StreamName NOT LIKE ''%ESSCONST'' AND ISR_streamName NOT LIKE ''%Beluga%'' AND ISR_streamName NOT LIKE ''%Minke%''/* AND ISR_streamName NOT LIKE ''%ICBCPP%''*/;

/*  apend _1 , _2 etc to positionId if it has more than one instance */

WITH DupPos
AS
(SELECT DISTINCT PositionId 
FROM  rmstg.[AllSource_Modelled] 
WHERE RowChecksum >1
)

UPDATE #allSourceModelled
SET PositionId =PositionId +  ''_'' + cast(Rowchecksum AS varchar(3) )  
WHERE PositionId  IN (SELECT PositionId FROM DupPos); 

-- Set RiskDate for all streams to match the AnalysisDate from the RuntimeParams MDS table
UPDATE  #allSourceModelled 
SET RiskDate = (SELECT CAST(RiskDateKey AS NVARCHAR(100)) FROM rmstg.CurrentDates);


--Set PricedSecurityName
--Set PricedSecurityName
UPDATE  #allSourceModelled
SET 
PricedSecurityName = PositionId + ''_'' + convert(varchar(8), RiskDate,112 )




--Set HoldingGroupName 
UPDATE  #allSourceModelled 
SET  HoldingGroupName  =
CASE WHEN ISR_StreamName LIKE ''%EBSCONST'' THEN ConstituentHoldingGroupName		 
	 WHEN ISR_StreamName LIKE ''%ESSCONST'' THEN ConstituentHoldingGroupName
	 WHEN ISR_streamName LIKE ''External'' THEN PortfolioName			-- NOTE: Confirm.
	 ELSE  ParentPortfolioCode
	 END;
	
UPDATE 
 #allSourceModelled
 SET ReportTagGroup 
    = (SELECT ReportTagGroup 
	   FROM RM_Reference.getReportTagGroup(ISR_StreamName  ,  InstrumentTypeCode,InstrumentGroupCode  , InstrumentClassCode, AssetClassCode/*, AccountingSystemAssetClass */) 
	   )
;

UPDATE #allSourceModelled
SET ExcludeOverride = ''Y'' 
WHERE 

ISR_streamName not like ''%CONST%''
AND ISR_streamName not like ''%EOS%''
AND ISR_Streamname NOT LIKE ''%FUT%''
AND ISR_StreamName NOT LIKE ''%ICBC%''		-- CM: Included to match manual process.
AND instrumentGroupCode NOT in(''FUT'', ''FWD'' )  -- Allow zero MV derivatives 
AND NOT (instrumentGroupCode = ''OPT'' AND MaturityDate > RiskDate)	--Exclude zero MV options if they at/after maturity date
AND NOT (instrumentGroupCode = ''SWAP'' AND coalesce(ExpiryDate	, MaturityDate) > RiskDate) --Exclude zero MV swaps if they are at/after maturity date
AND LocalTotalMarketValue  = 0;

update #allSourceModelled
set ReferenceRateCurvePay
 =
    CASE		 WHEN ReferenceRateCurvePay IN (''USD LIBOR'', ''USLIBOR'') THEN ''USD Swap - LIBOR''
				 WHEN ReferenceRateCurvePay = ''CAD Swap'' and ReferenceRateTermPay=''daily'' THEN ''CAD CORRA OIS (SP)''		-- Change in MSCI RM
						
			 WHEN ReferenceRateCurvePay = ''CDOR'' THEN ''CAD Swap''
			 WHEN ReferenceRateCurvePay = ''CORRA'' THEN ''CAD CORRA OIS (SP)''		-- Change in MSCI RM
			 WHEN ReferenceRateCurvePay IS NULL THEN ''''
			 ELSE ReferenceRateCurvePay
    END
	,
	ReferenceRateCurveRec =
    CASE		 WHEN ReferenceRateCurveRec IN (''USD LIBOR'', ''USLIBOR'') THEN ''USD Swap - LIBOR''		
					 WHEN ReferenceRateCurveRec = ''CAD Swap'' and ReferenceRateTermRec=''daily'' THEN ''CAD CORRA OIS (SP)''		-- Change in MSCI RM
				
			 WHEN ReferenceRateCurveRec = ''CDOR'' THEN ''CAD Swap''
			 WHEN ReferenceRateCurveRec = ''CORRA'' THEN ''CAD CORRA OIS (SP)''		-- Change in MSCI RM
			 WHEN ReferenceRateCurveRec IS NULL THEN ''''
			 ELSE ReferenceRateCurveRec
    END


-- Now nest temp table in output view

;with outputView
(	ExcludeOverride
,	ISR_streamName
,	ModelRuleEffective
,	SourceSystem
,	RiskDate
,	ModelRuleDefault
,	ModelRuleOverride
,	AccountingSystemSecId
,	AssetId
,	ExchangeCode
,	ExchangeId_Best
,	ExchangeId_BestType
,	ExchangeId_CUSIP
,	ExchangeId_ISIN
,	ExchangeId_RIC
,	ExchangeId_SEDOL
,	ExchangeId_TICKER  --Capitalized
,	LookThroughNameConstituents
,	PositionId
,	PositionName
,	PositionParentId
,	HoldingId
,	HoldingName
,	PricedSecurityName
,	SecId
,	SecIdParent  
,	securityName
,	securityNameParent
,	SwapIndexId
,	SwapName
,	Underlying
--,	AccountingSystemAsset
,	AssetClass
,	assetClassCode
,	FloatingRateIndicator
,	FwdLegTypeCode
,	InstrumentClassCode
,	instrumentGroupCode
,	InstrumentTypeCode
,	InstrumentTypeDesc
,	InvestmentType
,	IsZeroCoupon
,	OnMargin
,	OptionStyle
,	OptionType
,	SecurityType
,	StrikeType
,	SwapLegTypeCode
,	ExpiryDate
,	ForwardDate
,	IssueDate
,	MaturityDate
,	PurchaseDate
,	StartDate
,	ValuationDate
,	Currency
,	FxUnderlyingCcyCode
,	LocalPriceCcyCode
,	PriceCcyCode
,	QuoteCcyCode
,	SettlementCcyCode
--,	BasePrice


,	CorrectLocalMarketPrice
,	EntryPrice
,	FwdPrice
,	LatestClosingMarketPrice
,	LocalDirtyPrice
,	LocalMarketPrice
,	PriceInCad
,	StrikePrice
,	Amount
,	BaseAccruedInterest
,	BaseMarketValue
,	BaseTotalMarketValue
,	BaseTotalMarketValuePay
,	BaseTotalMarketValueRec
,	CalculatedAccruedInterest
,	ContractSize
,	CurrentRate
,	Duration
,	FxRateCost


,	LocalAccruedInterestNative
,	LocalMarketValue
,	LocalTotalMarketValue
,	LocalTotalMarketValuePay
,	LocalTotalMarketValueRec
,	minimumRate
,	Notional
,	PayNotional
,	Quantity
,	RecNotional
,	SharesOrParValue

,	SpotFXRate

,	BusinessDayRule
,	CompoundingFrequencyCode
,	ConstantTerm
,	couponFrequencyCode
,	CouponFrequencyPay
,	CouponFrequencyRec

,	CouponRate

,	CouponRatePay
,	CouponRateRec 

,	CouponType
,	DayCountBasis
,	DayCountBasisPay
,	DayCountBasisRec

,	ReferenceFrequency
,	ReferenceRateTerm
,	ReferenceRateTermPay
,	ReferenceRateTermRec
,	ResetFrequency
,	ResetRateFrequencyPay
,	ResetRateFrequencyRec

,	ResetSpreadPay
,	YieldRiskFactorTerm
,	RiskCountryCode
,	GicsCodeLowestLevel
,	PositionProxyPricedSecurityName
,	ProxyIndexCode

,	ProxyIndexName

	,ResetSpread
,	resetSpreadBP
,	ResetSpreadFI
,	ResetSpreadFI_BP
,	ResetSpreadRec
,	IssuerCode
,	IssuerCurve
,	IssuerName
,	referenceCurve
,	ReferenceRateCurvePay
,	ReferenceRateCurveRec
,	RisklessCurve
,	ConstituentHoldingGroupName
,	ParentPortfolioCode
,	PortfolioCode
,	PortfolioObjectiveCode
,	CounterParty
,	HoldingGroupName
,	EquityName

,	EquityPrice
,	EquityCurrency
,	PriceInLocalCcy
,	CurrencyCodePay
,	CurrencyCodeRec
,	ReportTagGroup
,	TagDerivationBasis
,	InvestmentStyle
,	FundMandate
,	FundStrategy
,	ManagementStyle
,	FundName
,	FundManager
,	BCIPoolRegion
,	EquityVP    

,	PortCalc
,	SettlementAmount
,	RepoTradeDate
,	RepoSettleDate
,	TerminationAmount
,	UnderlyingBondEDMsecurityId
,	UnderlyingBondIPSsecurityId
,	UnderlyingBondParAmount
,	UnderlyingInstrumentTypeCode
,	UnderlyingShortName

,	UnderlyingMaturityDate  
,   UnderlyingISIN
,   UnderyingREDCode 

,	UnderlyingCUSIP
,	GMRAYesNo
,	RehypothecationAllowed          
,	LocalFuturePrice              
,	SubPortfolioCode               
, BCIUltimateParentIssuerName
, BCIGicsSector
, InstrumentClass
, InstrumentGroup
, InstrumentType
, PortfolioName
, PurchaseDateRec
, PurchaseDatePay
, SwapLegTypeCodePay
, SwapLegTypeCodeRec
, BCIMaturityDate
, BCIIssueDate

, BCIFXRate


, BenchmarkID
, PEInvestmentType
, DiscountCurve
, spreadCurve
, LienType
, FacilityType
, FairSpread
, MaturityBucket


)
as
(
SELECT
--block 1
	 ExcludeOverride
,	 ISR_streamName
,	 isnull(ModelRuleOverride,ModelRuleDefault) as ModelRuleEffective
,	 SourceSystem
,	convert(varchar(8), RiskDate, 112) as RiskDate
,	 ModelRuleDefault
,	 ModelRuleOverride
,	 AccountingSystemSecId
,	 AssetId
,	 ExchangeCode
,	 ExchangeId_Best
,	 ExchangeId_BestType
,	 ExchangeId_CUSIP
,	 ExchangeId_ISIN
,	 ExchangeId_RIC
,	 ExchangeId_SEDOL
,	 ExchangeId_TICKER
,	 LookThroughNameConstituents
,	 PositionId
,	 PositionName
,	 PositionParentId
,	 PositionId as HoldingId
,    CASE WHEN ISR_streamName = ''SCD_CDS'' THEN SwapName 
								ELSE PositionName END	as HoldingName
,	 PricedSecurityName
,	 SecId
,	 SecIdParent
,	 securityName
,	 securityNameParent
,	 SwapIndexId
,	 SwapName
,	 Underlying
--,	 AccountingSystemAssetClass
,	 AssetClass
,	 assetClassCode
,	 FloatingRateIndicator
,	 FwdLegTypeCode
,	 InstrumentClassCode
,	 instrumentGroupCode
,	 InstrumentTypeCode
,	 InstrumentTypeDesc
,	 InvestmentType
,	 IsZeroCoupon
,	 OnMargin
,	 OptionStyle
,	 OptionType
,	 SecurityType
,	 StrikeType
,	 SwapLegTypeCode
,	 convert(varchar(8), ExpiryDate, 112) as ExpiryDate
,	 convert(varchar(8), ForwardDate, 112) as ForwardDate
,	 convert(varchar(8), IssueDate, 112) as IssueDate
,	 convert(varchar(8), MaturityDate, 112) as MaturityDate
,	 convert(varchar(8), PurchaseDate, 112) as PurchaseDate
,	 convert(varchar(8), StartDate, 112) as StartDate
,	 convert(varchar(8), ValuationDate,112) as ValuationDate
,	 Currency
,	 FxUnderlyingCcyCode
,	 LocalPriceCcyCode
,	 PriceCcyCode
,	 QuoteCcyCode
,	 SettlementCcyCode
--,	 BasePrice

,	 CorrectLocalMarketPrice
,	 EntryPrice
,	 FwdPrice
,	 LatestClosingMarketPrice
,	 LocalDirtyPrice
,	 LocalMarketPrice
,	 PriceInCad
,	 StrikePrice
,	 Amount
,	 BaseAccruedInterest
,	 BaseMarketValue
,	 BaseTotalMarketValue
,	 BaseTotalMarketValuePay
,	 BaseTotalMarketValueRec
,	CalculatedAccruedInterest
,	 ContractSize
,	 CurrentRate
,	 Duration
,	 FxRateCost


,	 LocalAccruedInterestNative
,	 LocalMarketValue
,	 LocalTotalMarketValue
,	 LocalTotalMarketValuePay
,	 LocalTotalMarketValueRec
,	 minimumRate
,	 Notional
,	 PayNotional
,	 Quantity
,	 RecNotional
,	 SharesOrParValue

,	 SpotFXRate

,	 BusinessDayRule
,	 CompoundingFrequencyCode
,	 ConstantTerm
,	 couponFrequencyCode
,	 CouponFrequencyPay
,	 CouponFrequencyRec

,	 CouponRate
/**/
,	 CouponRatePay
,	 CouponRateRec  /*  problem col*/
/**/
,	 CouponType
,	 DayCountBasis
,	 DayCountBasisPay
,	 DayCountBasisRec

,	 ReferenceFrequency
,	 ReferenceRateTerm
,	 ReferenceRateTermPay
,	 ReferenceRateTermRec
,	 ResetFrequency
,	 ResetRateFrequencyPay
,	 ResetRateFrequencyRec

,	 ResetSpreadPay
,	 YieldRiskFactorTerm
,	 RiskCountryCode
,	 GicsCodeLowestLevel
,	 PositionProxyPricedSecurityName
,	 ProxyIndexCode

,	 ProxyIndexName

	, ResetSpread
,	 resetSpreadBP
,	 ResetSpreadFI
,	 ResetSpreadFI*100 as ResetSpreadFI_BP
,	 ResetSpreadRec
,	 IssuerCode
,	 IssuerCurve
,	 IssuerName
,	 referenceCurve
,	 ReferenceRateCurvePay
,	 ReferenceRateCurveRec
,	 RisklessCurve
,	 ConstituentHoldingGroupName
,	 ParentPortfolioCode
,	 PortfolioCode
,	 PortfolioObjectiveCode
,	 CounterParty 
,     HoldingGroupName
,	 EquityName       
 
,	  EquityPrice
,	 EquityCurrency
,	 PriceInLocalCcy
, CurrencyCodePay
, CurrencyCodeRec
,	 RTG.ReportTagGroup
,	 PFT.TagDerivationBasis
,     PFT.InvestmentStyle
,	 convert(varchar(8), PFT.FundMandate, 112) AS FundMandate
,     PFT.FundStrategy
,	 PFT.ManagementStyle
,     PFT.FundName
,     PFT.FundManager
,     PFT.BCIPoolRegion
,     PFT.EquityVP 

 ,  PortCalc
 ,  try_convert(numeric(38,6), SettlementAmount ) AS SettlementAmount
 ,  convert(varchar(8), RepoTradeDate, 112) as RepoTradeDate
 ,  convert(varchar(8), RepoSettleDate, 112) as RepoSettleDate 
 ,  try_convert(float, TerminationAmount ) AS TerminationAmount
 ,  UnderlyingBondEDMsecurityId
 ,  UnderlyingBondIPSsecurityId
 ,  try_convert(numeric(38,6), UnderlyingBondParAmount ) AS UnderlyingBondParAmount
 ,  UnderlyingInstrumentTypeCode
 ,  UnderlyingShortName
 ,   convert(varchar(8), UnderlyingMaturityDate, 112)	UnderlyingMaturityDate  
,   UnderlyingISIN
,   UnderyingREDCode 
 ,  UnderlyingCUSIP
 ,  GMRAYesNo
 ,  RehypothecationAllowed     
 , try_convert(float, LocalFuturePrice)   AS LocalFuturePrice 
 , SubPortfolioCode  
 , BCIUltimateParentIssuerName
 , BCIGicsSector
, InstrumentClass
, InstrumentGroup
, InstrumentType
, PortfolioName
,  convert(varchar(8), PurchaseDateRec , 112) as PurchaseDateRec 
,  convert(varchar(8), PurchaseDatePay, 112)  as PurchaseDatePay
, SwapLegTypeCodePay
, SwapLegTypeCodeRec
, convert(varchar(8), BCIMaturityDate, 112) BCIMaturityDate
,  convert(varchar(8), BCIIssueDate, 112) as  BCIIssueDate

, try_convert(float,BCIFXRate ) AS  BCIFXRate
, BenchmarkID

, PEInvestmentType
, DiscountCurve
, spreadCurve
, LienType
, FacilityType
, FairSpread
, CASE 
	WHEN InstrumentClass = ''DERIVATIVE'' OR InstrumentTypeCode LIKE ''%REPO%''
		THEN CASE		
			WHEN DATEDIFF(DAY,RiskDate,MaturityDate) < 1 THEN ''''
			WHEN DATEDIFF(DAY,RiskDate,MaturityDate) < 8 THEN ''1 to 7 Days''
			WHEN DATEDIFF(DAY,RiskDate,MaturityDate) < 31 THEN ''8 to 30 Days''
			WHEN DATEDIFF(DAY,RiskDate,MaturityDate) < 91 THEN ''31 to 90 Days''
			WHEN DATEDIFF(DAY,RiskDate,MaturityDate) < 361 THEN ''91 to 360 Days''
			WHEN DATEDIFF(DAY,RiskDate,MaturityDate) > 360 THEN ''More than 360 Days''
		END	
		ELSE ''''
		END AS MaturityBucket




FROM
#allSourceModelled
cross APPLY RM_Reference.getReportTagGroup(ISR_streamName,InstrumentTypeCode, instrumentGroupCode, InstrumentClassCode, assetClassCode/*, AccountingSystemAssetClass */) RTG
cross APPLY [RM_Reference].[getReportTagValue_Portfolio](SourceSystem, ISR_streamName, HoldingGroupName, ''Working'') PFT
where 
 ExcludeOverride <> ''Y''
 )
 select * from outputView
 where SwapLegTypeCode <> ''FIXED_LEG''
 '
EXECUTE(@SQL)