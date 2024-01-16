USE RMRepository
DECLARE @portfolioCode VARCHAR(5);
SET @portfolioCode = '?'; -----------E0075, E0178, E0063


;WITH
UnitPortfolios
as
(  SELECT distinct
  pc.SCD_PORTFOLIO_CODE AS srcPoolFundCode,
  Pos.LOWEST_LEVEL_PORTFOLIO   PortfolioCode
  FROM srcLanding.scdMaster_FN_POSITION pos
   join srcLanding.scdMaster_PORTFOLIO_CONSOLIDATED pc ON (pos.EDM_PORTFOLIO_ID = pc.EDM_PORTFOLIO_ID)
WHERE 
  pc.SCD_PORTFOLIO_CODE = @portfolioCode /* change to MDS lookup if more instances  */ 
  AND pc.FUND_TYPE_CODE = 'POOL'
),

Contra
 as
 (SELECT 1 Factor, 'UNITS' Destination
 UNION ALL   
 SELECT -1 Factor, 'NEUTRALIZATION' Destination
 )
 , DistributionValues
AS (
SELECT  Pos.LOWEST_LEVEL_PORTFOLIO,
		coalesce(s.scd_sec_id, S.IPS_SECURITY_ID) [IPS_SECURITY_ID],
		Pos.MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV  tgtPoolFundCodeTotalMvBase,Pos.EFFECTIVE_DATE
FROM	
		RMRepository.srcLanding.scdMaster_FN_POSITION  Pos 
join    srcLanding.scdMaster_FN_PORTFOLIO  P on (p.EDM_PORTFOLIO_ID = Pos.EDM_PORTFOLIO_ID )
join    srcLanding.scdMaster_INSTRUMENT_CONSOLIDATED S on (Pos.EDM_INSTRUMENT_ID = S.EDM_INSTRUMENT_ID)

WHERE 
			P.FUND_TYPE_CODE = 'POOL'
		AND Pos.SUB_PORTFOLIO_CODE	= 'E0E0225'
		AND coalesce(s.scd_sec_id, S.IPS_SECURITY_ID) = @portfolioCode ------------------------------------Portfolio Code parameter used
)
,
SourceValues as
(
  SELECT pc.EDM_PORTFOLIO_ID,
  pc.SCD_PORTFOLIO_CODE AS srcPoolFundCode
  ,sum(pos.MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV) AS srcPoolFundCodeTotalMvBase
  FROM srcLanding.scdMaster_FN_POSITION pos
   join srcLanding.scdMaster_PORTFOLIO_CONSOLIDATED pc ON (pos.EDM_PORTFOLIO_ID = pc.EDM_PORTFOLIO_ID)
  WHERE 
  pc.SCD_PORTFOLIO_CODE = @portfolioCode /* change to MDS lookup if more instances  */  ------------------------------------Portfolio Code parameter used
  AND pc.FUND_TYPE_CODE = 'POOL'
  GROUP BY pc.SCD_PORTFOLIO_CODE,pc.EDM_PORTFOLIO_ID
  )
  ,
  Scales
  AS
  (
 SELECT 
 c.Destination,
 LOWEST_LEVEL_PORTFOLIO,
 srcPoolFundCode , 
 srcPoolFundCodeTotalMvBase , 
 tgtPoolFundCodeTotalMvBase , 
 cast(tgtPoolFundCodeTotalMvBase AS float)/  cast( isnull(srcPoolFundCodeTotalMvBase ,0) AS float) * c.Factor Scale
 FROM SourceValues sv	JOIN DistributionValues dv	 ON (dv.IPS_SECURITY_ID = sv.srcPoolFundCode) 
 CROSS JOIN Contra c	
 ) 
,
UnitsPositions
AS
(
SELECT
asm.*,
s.Scale ,
CASE  s.Destination
	WHEN 'UNITS' then up.srcPoolFundCode + '_UNITS'  
	WHEN 'NEUTRALIZATION' THEN 'RISKNEU' + up.srcPoolFundCode
	END
	AS ParentPortfolioCode_Override,   /*  this is the destination portfolio  */
'UNIT_REALLOCATION' as ISR_streamName_Override,
/* derive new position id  */
CASE  s.Destination
	WHEN 'UNITS' then up.srcPoolFundCode + '_UNITS'  
	WHEN 'NEUTRALIZATION' THEN 'RISKNEU' + up.srcPoolFundCode 
	END + '_' +  PositionId 
	AS	PositionId_OVerride,

/* scale these columns for allocated positions */
s.Scale  * Amount   AS   Amount_Override, 
s.Scale  * BaseAccruedInterest  AS  BaseAccruedInterest_Override, 
s.Scale  * BaseTotalMarketValue  AS   BaseTotalMarketValue_Override, 
s.Scale  * BaseMarketValue  AS   BaseMarketValue_Override, 
s.Scale  * LocalAccruedInterestNative  AS   LocalAccruedInterestNative_Override, 
s.Scale  * LocalMarketValue  AS   LocalMarketValue_Override, 
s.Scale  * LocalTotalMarketValue  AS   LocalTotalMarketValue_Override, 
s.Scale  * Notional  AS   Notional_Override, 
1 AS   Quantity_Override,   /*  abs(s.Scale)  * Quantity   for quantity use absolute to prevent RM from re-flipping sign of neutralization */
s.Scale  * SharesOrParValue  AS  SharesOrParValue_Override, 
s.Scale  * PayNotional  AS   PayNotional_Override, 
s.Scale  * RecNotional  AS   RecNotional_Override, 
s.Scale  * LocalTotalMarketValuePay  AS   LocalTotalMarketValuePay_Override, 
s.Scale  * LocalTotalMarketValueRec  AS   LocalTotalMarketValueRec_Override, 
s.Scale  * BaseTotalMarketValuePay  AS   BaseTotalMarketValuePay_Override, 
s.Scale  * BaseTotalMarketValueRec  AS   BaseTotalMarketValueRec_Override, 
s.Scale  * CalculatedAccruedInterest  AS   CalculatedAccruedInterest_Override, 
s.Scale  * SettlementAmount  AS  SettlementAmount_Override, 
s.Scale  * TerminationAmount  AS   TerminationAMOUNT_Override, 
s.Scale  * UnderlyingBondParAmount  AS   UnderlyingBondParAmount_Override, 
s.Scale  * AmortizedBookValueLocal  AS   AmortizedBookValueLocal_Override
FROM rmstg.AllSource_Modelled asm  
JOIN UnitPortfolios up ON (asm.PortfolioCode	= up.PortfolioCode	)
CROSS JOIN Scales s
WHERE asm.ExcludeOverride = 'N'
), modelled as 

(
SELECT  
RiskDate,	SourceSystem,	
ISR_streamName_Override AS ISR_streamName,	
ExcludeOverride,	ModelExceptionOverride,	Currency,	FxUnderlyingCcyCode,	LocalPriceCcyCode,	PriceCcyCode,	
QuoteCcyCode,	SettlementCcyCode,	AccountingSystemAssetClass,	AssetClass,	assetClassCode,	instrumentGroupCode,	InstrumentTypeCode,	InstrumentTypeDesc,	
InvestmentType,	OptionType,	SwapLegTypeCode,	FwdLegTypeCode,	ExpiryDate,	ForwardDate,	IssueDate,	MaturityDate,	ValuationDate,	ConstituentHoldingGroupName,	
PortfolioCode,	PortfolioObjectiveCode,	AccountingSystemSecId,	AssetId,	ExchangeId_CUSIP,	ExchangeId_ISIN,	ExchangeCode,	ExchangeId_RIC,	ExchangeId_SEDOL,	
ExchangeId_Ticker,	ExchangeId_Best,	
PositionId_Override AS PositionId,	
PositionName,	PositionParentId,	SecId,	SecIdParent,	securityName,	securityNameParent,	SwapName,	
HasLookthrough,	IsLookthroughConstituent,	LookThroughNameConstituents,	LookthroughScalingMethod,	ParentOrConstituent,	PersistOrCollapse,	BusinessDayRule,	
CompoundingFrequencyCode,	ConstantTerm,	CounterParty,	couponFrequencyCode,	CouponRate,	CouponType,	DayCountBasis,	GicsCodeLowestLevel,	IssuerCode,	IssuerName,	
IsZeroCoupon,	OptionStyle,	PositionProxyPricedSecurityName,	referenceCurve,	ReferenceFrequency,	ReferenceRateTerm,	ResetFrequency,	ResetSpread,	RiskCountryCode,	
RisklessCurve,	SecurityType,	StrikeType,	IssuerDriver,	Model_001,	Model_002,	Model_003,	SwapIndexId,	FloatingRateIndicator,	OnMargin,	CorrectLocalMarketPrice,	
EntryPrice,	FwdPrice,	LatestClosingMarketPrice,	LocalMarketPrice,	PriceInCad,	SpotFXRate,	StrikePrice,	resetSpreadBP,	ResetSpreadFI,	ResetSpreadRec,	
Amount_Override AS Amount,	
BaseAccruedInterest_Override AS BaseAccruedInterest,	
BaseMarketValue_Override AS BaseMarketValue,	
BaseTotalMarketValue_Override AS BaseTotalMarketValue,	
ContractSize,	CurrentRate,	
LocalAccruedInterestNative_Override AS LocalAccruedInterestNative,	
LocalMarketValue_Override AS LocalMarketValue,	
LocalTotalMarketValue_Override AS LocalTotalMarketValue,	
minimumRate,	
Notional_Override AS Notional,	
Quantity_Override AS Quantity,	
SharesOrParValue_Override AS SharesOrParValue,	
Duration,	rptAC_001,	rptGlb_001,	rptPort_001,	rptPos_001,	rptSys_001,	rptUncl_001,	
ParentPortfolioCode_Override AS ParentPortfolioCode,	
ModelRuleDefault,	ModelRuleOverride,	ProxyIndexName,	ProxyIndexCode,	IssuerCurve,	InstrumentClassCode,	ReportTagGroup,	FxRateCost,	BasePrice,	
PayNotional_Override AS PayNotional,	
RecNotional_Override AS RecNotional,	
Underlying,	CouponFrequencyPay,	CouponRatePay,	DayCountBasisPay,	ReferenceRateCurvePay,	ReferenceRateTermPay,	ResetRateFrequencyPay,	ResetSpreadPay,	
CouponFrequencyRec,	DayCountBasisRec,	ReferenceRateCurveRec,	ReferenceRateTermRec,	ResetRateFrequencyRec,	StartDate,	PurchaseDate,	EquityName,	EquityPrice,	
EquityCurrency,	PriceInLocalCcy,	
LocalTotalMarketValuePay_Override AS LocalTotalMarketValuePay,	
LocalTotalMarketValueRec_Override AS LocalTotalMarketValueRec,	
BaseTotalMarketValuePay_Override AS BaseTotalMarketValuePay,	
BaseTotalMarketValueRec_Override AS BaseTotalMarketValueRec,	
CouponRateRec,	ExchangeId_BestType,	LocalDirtyPrice,	PricedSecurityName,	
CalculatedAccruedInterest_Override AS CalculatedAccruedInterest,	
YieldRiskFactorTerm,	
ROW_NUMBER() OVER (PARTITION BY PositionId_Override ORDER BY PositionId)  AS RowChecksum,	
ParentPortfolioCode_Override AS HoldingGroupName,	
CurrencyCodePay,	
CurrencyCodeRec,	PortCalc,	
SettlementAmount_Override AS SettlementAmount,	
RepoTradeDate,	RepoSettleDate,	
TerminationAMOUNT_Override AS TerminationAMOUNT,	
UnderlyingBondEDMsecurityId,	UnderlyingBondIPSsecurityId,	
UnderlyingBondParAmount_Override AS UnderlyingBondParAmount,	
UnderlyingInstrumentTypeCode,	UnderlyingShortName,	UnderlyingCUSIP,	GMRAYesNo,	RehypothecationAllowed,	LocalFuturePrice,	
SubPortfolioCode,	
AmortizedBookValueLocal_Override AS AmortizedBookValueLocal,	
BCIUltimateParentIssuerName,	BCIGicsSector,	InstrumentClass,	InstrumentGroup,	InstrumentType,	PortfolioName,	
FundManager,	FundName,	PurchaseDateRec,	PurchaseDatePay,	SwapLegTypeCodePay,	SwapLegTypeCodeRec,	BCIIssueDate,	BCIMaturityDate,	BCIFXRate,	BenchmarkID,	
MDSVersion,	MDSVersionNbr
 FROM  UnitsPositions
 )

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
,    CASE WHEN ISR_streamName = 'SCD_CDS' THEN SwapName 
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
 ,   null as 	UnderlyingMaturityDate  
,   null as UnderlyingISIN
,   null as UnderyingREDCode 
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

, null PEInvestmentType
, null DiscountCurve
, null spreadCurve
, null LienType
, null FacilityType
, null FairSpread
, '' AS MaturityBucket


/*,	 HasLookthrough
,	 IsLookthroughConstituent
,	 IssuerDriver
,	 LookthroughScalingMethod
,	 ParentOrConstituent
,	 PersistOrCollapse
,	 TimeSeriesDriver1  */


FROM
modelled --rmstg.[AllSource_Modelled]
cross APPLY RM_Reference.getReportTagGroup(ISR_streamName,InstrumentTypeCode, instrumentGroupCode, InstrumentClassCode, assetClassCode/*, AccountingSystemAssetClass */) RTG
cross APPLY [RM_Reference].[getReportTagValue_Portfolio](SourceSystem, ISR_streamName, HoldingGroupName, 'Working') PFT
where 
 ExcludeOverride <> 'Y'
 and ParentPortfolioCode like '%?%' ---------------------Change ParentPortfolioCode to Variable code value passed in line 3