 -----------COPY RAW DATA--------------------------------------------
--******CHANGE THE DATE TO FRIDAY's OR LAST BUSINESS DAY's DATE accordingly**********************************************************

-- DECLARE @valuation_date DATE = '2022-11-04' --YYYY-MM-DD
-- @valuation_date is replaced with ? for pyodbc to work
 /*

 The data is to be pasted in the Positonal Level tab of the LiquidsDerivative PV Validation Date file.

 CHANGE EFFECTIVE DATE PARAMETER to match the desired report date.

 --******CHANGE THE DATE TO FRIDAY's OR LAST BUSINESS DAY's DATE accordingly***********************************************************

 */
 USE RiskRaw;

 WITH PositionalLevelData AS (
  
  SELECT DISTINCT FORMAT(CONVERT(DATE,POS.EFFECTIVE_DATE),'yyyyMMdd') AS VALUATION_DATE
	  ,POS.LOWEST_LEVEL_PORTFOLIO AS PORTFOLIO_CODE
	  ,PORTFOLIO_LONG_NAME
	  ,ISNULL(CP.PARENT_PORTFOLIO_CODE,POS.LOWEST_LEVEL_PORTFOLIO) AS PARENT_PORTFOLIO_CODE
	  ,I.LIST_LONG_VALUE AS INSTRUMENT_TYPE
	  ,S.INSTRUMENT_TYPE_CODE
	  ,S.EDM_INSTRUMENT_ID AS EDM_SEC_ID
	  ,S.SCD_SEC_ID
	  ,S.SHORT_NAME AS SECURITY_NAME
	  ,PARTY.LONG_COMPANY_NAME AS ISSUER
	  ,POS.LOCAL_CURRENCY_CODE AS LOCAL_PRICE_CURRENCY_CODE
	  ,POS.FX_RATE
	  ,FORMAT(CONVERT(DATE,S.ISSUE_DATE),'yyyyMMdd') AS ISSUE_DATE
	  --,FORMAT(CONVERT(DATE,FI.MATURITY_DATE),'yyyyMMdd') AS MATURITY_DATE
	  ,pos.MARKET_PRICE_LOCAL
	  ,pos.QUANTITY, ACCRUED_INTEREST_FUTURE_VALUE_LOCAL, MARKET_VALUE_LOCAL
	  ,pos.MARKET_VALUE_ACCRUED_INTEREST_LOCAL_NAV AS LOCAL_TOTAL_MV
	  ,pos.MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV AS BASE_TOTAL_MV, FI.*
  FROM RiskRaw.[rpt_SCD].[Master_FN_POSITION]  POS --for system_time as of '06/01/2020' POS
  LEFT JOIN RiskRaw.[rpt_SCD].[Master_FN_INSTRUMENT_CONSOLIDATED] S ON S.EDM_INSTRUMENT_ID = POS.EDM_INSTRUMENT_ID
  LEFT JOIN RiskRaw.[rpt_SCD].[Master_FN_INSTRUMENT_FIXED_INCOME_DETAIL] FI ON FI.EDM_INSTRUMENT_ID = S.EDM_INSTRUMENT_ID
  LEFT JOIN RiskRaw.[rpt_SCD].[Master_FN_LIST_VALUE] I on I.LIST_SHORT_VALUE = s.INSTRUMENT_TYPE_CODE AND I.LIST_CODE = 'INSTTYPE'
  LEFT JOIN RiskRaw.[rpt_SCD].[Master_FN_PARTY_CONSOLIDATED] PARTY ON PARTY.EDM_PARTY_ID = S.EDM_PARTY_ID
  LEFT JOIN RiskRaw.[rpt_SCD].[Master_FN_PORTFOLIO_CONSOLIDATED] PF ON PF.EDM_PORTFOLIO_ID = POS.EDM_PORTFOLIO_ID
  LEFT JOIN MDS_ISR.[mdm].[ENRICHMENT_viwPortfolioParentMap] CP ON CP.PORTFOLIO_CODE = POS.LOWEST_LEVEL_PORTFOLIO
                                                                        AND CP.SOURCE = 'SCD'
                                                                        AND (S.ASSET_CLASS_CODE = CP.ASSET_CLASS_CODE
                                                                             OR CP.ASSET_CLASS_CODE IS NULL
                                                                             OR CP.ASSET_CLASS_CODE = 'NULL')
  WHERE 
  POS.EFFECTIVE_DATE = ? 
  --AND POS.PORTFOLIO_CALCULATION = 'ABOR' AND POS.SOURCE = 'SCD_TRXGL'
  AND POS.PORTFOLIO_CALCULATION = 'DWH_IBOR' AND POS.SOURCE = 'SCD_MAIN'
  AND Pos.MARKET_VALUE_ACCRUED_INTEREST_LOCAL_NAV != 0
 and fi.INTERNAL_FINANCING_INDICATOR = 1
  --ORDER BY 2,5,7
  )

SELECT	
		'N' [ExcludeOverride] 
		,'SCD_LIQUIDS' [ISR_streamName] 
		,'IFT Loans' [ModelRuleEffective] 
		,'SCD' [SourceSystem] 
		,VALUATION_DATE [RiskDate]
		,'IFT Loans' [ModelRuleDefault]
		,'' [ModelRuleOverride]
		,EDM_SEC_ID [AccountingSystemSecId]
		,CONCAT(PORTFOLIO_CODE,'_',EDM_SEC_ID) [AssetId] 
		,'' AS ExchangeCode
		,'' AS ExchangeId_Best
		,'' AS ExchangeId_BestType
		,'' AS ExchangeId_CUSIP
		,'' AS ExchangeId_ISIN
		,'' AS ExchangeId_RIC
		,'' AS ExchangeId_SEDOL
		,'' AS ExchangeId_TICKER
		,'' AS LookThroughNameConstituents
		,CONCAT(PORTFOLIO_CODE,'_',EDM_SEC_ID) [PositionId]
		,SECURITY_NAME [PositionName]
		,'' AS PositionParentId
		,CONCAT(PORTFOLIO_CODE,'_',EDM_SEC_ID) [HoldingId]
		, SECURITY_NAME [HoldingName]
		,CONCAT(PORTFOLIO_CODE,'_',EDM_SEC_ID,'_',VALUATION_DATE) [PricedSecurityName]
		,EDM_SEC_ID [SecId] 
		,'' AS SecIdParent
		,SECURITY_NAME [securityName]
		,'' AS securityNameParent
		,'' AS SwapIndexId
		,'' AS SwapName
		,'' AS Underlying
		,'' AS AssetClass
		,'' AS assetClassCode
		,'' AS FloatingRateIndicator
		,'' AS FwdLegTypeCode
		,'' AS InstrumentClassCode
		,'' AS instrumentGroupCode
		,INSTRUMENT_TYPE_CODE [InstrumentTypeCode]
		,INSTRUMENT_TYPE [InstrumentTypeDesc]
		,'' AS InvestmentType
		,'' AS IsZeroCoupon
		,'' AS OnMargin
		,'' AS OptionStyle
		,'' AS OptionType
		,'' AS SecurityType
		,'' AS StrikeType
		,'' AS SwapLegTypeCode
		,'' AS ExpiryDate
		,'' AS ForwardDate
		,FORMAT(CONVERT(DATE,ISSUE_DATE),'yyyyMMdd') [IssueDate]
		,FORMAT(CONVERT(DATE,MATURITY_DATE),'yyyyMMdd') [MaturityDate]
		,'' AS PurchaseDate
		,'' AS StartDate
		,VALUATION_DATE [ValuationDate]
		,'' AS Currency
		,''AS FxUnderlyingCcyCode
		,LOCAL_PRICE_CURRENCY_CODE [LocalPriceCcyCode]
		,'' AS PriceCcyCode
		,'' AS QuoteCcyCode
		,'' AS SettlementCcyCode
		,'' AS CorrectLocalMarketPrice
		,'' AS EntryPrice
		,'' AS FwdPrice
		,'' AS LatestClosingMarketPrice
		,'' AS LocalDirtyPrice
		,FORMAT(MARKET_PRICE_LOCAL,'##') [LocalMarketPrice]
		,'' AS PriceInCad
		,'' AS StrikePrice
		,FORMAT(QUANTITY, '###.##') [Amount]
		,'' AS BaseAccruedInterest
		,'' AS BaseMarketValue
		,FORMAT(BASE_TOTAL_MV,'###.##') [BaseTotalMarketValue]
		,'' AS BaseTotalMarketValuePay
		,'' AS BaseTotalMarketValueRec
		,((CAST(ACCRUED_INTEREST_FUTURE_VALUE_LOCAL AS numeric(38,24))*100)/QUANTITY) [CalculatedAccruedInterest] ---------decimal places 6 instead of 9
		,'' AS ContractSize
		,'' AS CurrentRate
		,'' AS Duration
		,'' AS FxRateCost
		,FORMAT(ACCRUED_INTEREST_FUTURE_VALUE_LOCAL,'###.##') [LocalAccruedInterestNative]
		,FORMAT(MARKET_VALUE_LOCAL,'###.##') [LocalMarketValue]
		,FORMAT(LOCAL_TOTAL_MV,'###.##') [LocalTotalMarketValue]
		,'' AS LocalTotalMarketValuePay
		,'' AS LocalTotalMarketValueRec
		,'' AS minimumRate
		,'' AS Notional
		,'' AS PayNotional
		,'1' [Quantity]
		,'' AS RecNotional
		,FORMAT(QUANTITY,'###.##') [SharesOrParValue]
		,FORMAT(FX_RATE, '#') [SpotFXRate] 
		,'' AS BusinessDayRule
		,'' AS CompoundingFrequencyCode
		,'' AS ConstantTerm
		,'quarterly' [couponFrequencyCode]
		,'' AS CouponFrequencyPay
		,'' AS CouponFrequencyRec
		,FORMAT(COUPON_RATE,'###.###') [CouponRate]
		,'' AS CouponRatePay
		,'' AS CouponRateRec
		,COUPON_TYPE_CODE [CouponType]
		,'dayCount_Act_365' [DayCountBasis]
		,'' AS DayCountBasisPay
		,'' AS DayCountBasisRec
		,'' AS ReferenceFrequency
		,'' AS ReferenceRateTerm
		,'' AS ReferenceRateTermPay
		,'' AS ReferenceRateTermRec
		,'' AS ResetFrequency
		,'' AS ResetRateFrequencyPay
		,'' AS ResetRateFrequencyRec
		,'' AS ResetSpreadPay
		,'' AS YieldRiskFactorTerm
		,'CA' [RiskCountryCode]
		,'' AS GicsCodeLowestLevel
		,'' AS PositionProxyPricedSecurityName
		,'' AS ProxyIndexCode
		,'' AS ProxyIndexName
		,FORMAT(RESET_SPREAD,'###0.###') [ResetSpread]
		,FORMAT((RESET_SPREAD*100),'###.#') [resetSpreadBP]
		,'' AS ResetSpreadFI
		,'' AS ResetSpreadFI_BP
		,'' AS ResetSpreadRec
		,ISNULL(ISSUER,'British Columbia Investment Management Corp') [IssuerCode]
		,'CAD Financial AA' [IssuerCurve]
		,'' AS IssuerName
		,'CAD Swap' [referenceCurve]
		,'' AS ReferenceRateCurvePay
		,'' AS ReferenceRateCurveRec
		,'CAD Govt' [RisklessCurve]
		,'' AS ConstituentHoldingGroupName
		,PARENT_PORTFOLIO_CODE [ParentPortfolioCode]
		,PORTFOLIO_CODE [PortfolioCode]
		,'' AS PortfolioObjectiveCode
		,'' AS CounterParty
		,PARENT_PORTFOLIO_CODE [HoldingGroupName]
		,'' AS EquityName
		,'' AS EquityPrice
		,'' AS EquityCurrency
		,'' AS PriceInLocalCcy
		,'' AS CurrencyCodePay
		,'' AS CurrencyCodeRec
		,'' AS ReportTagGroup
		,'' AS TagDerivationBasis
		,'' AS InvestmentStyle
		,'' AS FundMandate
		,'' AS FundStrategy
		,'' AS ManagementStyle
		,'' AS FundName
		,'' AS FundManager
		,'' AS BCIPoolRegion
		,'' AS EquityVP
		,'DWH_IBOR' [PortCalc]
		,'' AS SettlementAmount
		,'' AS RepoTradeDate
		,'' AS RepoSettleDate
		,'' AS TerminationAmount
		,'' AS UnderlyingBondEDMsecurityId
		,'' AS UnderlyingBondIPSsecurityId
		,'' AS UnderlyingBondParAmount
		,'' AS UnderlyingInstrumentTypeCode
		,'' AS UnderlyingShortName
		,'' AS UnderlyingMaturityDate
		,'' AS UnderlyingISIN
		,'' AS UnderyingREDCode
		,'' AS UnderlyingCUSIP
		,'' AS GMRAYesNo
		,'' AS RehypothecationAllowed
		,'' AS LocalFuturePrice
		,'' AS SubPortfolioCode
		,ISNULL(ISSUER,'British Columbia Investment Management Corp') [BCIUltimateParentIssuerName]
		,'Financials' [BCIGicsSector]
		,'' AS InstrumentClass
		,'' AS InstrumentGroup
		,INSTRUMENT_TYPE [InstrumentType]
		,PORTFOLIO_LONG_NAME [PortfolioName]
		,'' AS PurchaseDateRec
		,'' AS PurchaseDatePay
		,'' AS SwapLegTypeCodePay
		,'' AS SwapLegTypeCodeRec
		,FORMAT(CONVERT(DATE,MATURITY_DATE),'yyyyMMdd') [BCIMaturityDate]
		,FORMAT(CONVERT(DATE,ISSUE_DATE),'yyyyMMdd') [BCIIssueDate]
		,FORMAT(FX_RATE, '#') [BCIFXRate]
		,'CASH.SC.CASHPROXY_CAD@rmgBenchmarks' [BenchmarkID]
		,'' AS PEInvestmentType
		,'' AS DiscountCurve
		,'' AS spreadCurve
		,'' AS LienType
		,'' AS FacilityType
		,'' AS FairSpread
		,'' AS MaturityBucket
FROM PositionalLevelData
--WHERE MATURITY_DATE > '20220708'
WHERE PARENT_PORTFOLIO_CODE NOT IN ('EBRONCO', 'E0071N','ME0017','ME0044','ME0358','E0074','ME0025','ME173B','ME170D','ME170UIN') 
ORDER BY PORTFOLIO_CODE,INSTRUMENT_TYPE, EDM_SEC_ID

