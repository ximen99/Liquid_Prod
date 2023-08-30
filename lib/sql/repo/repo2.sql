SELECT FORMAT(CONVERT(DATE,AsOfDate),'yyyyMMdd') [Valuation_date], CUSIP [BCI_underlyingCUSIP], Counterparty [counterparty], PARValue [BCI_underlyingParAmount]
,'Repurchase Agreement' [InstrumentType],'REPO' [InstrumentTypeCode]
FROM [RiskRaw].[rpt_DerivativeOp].[VW_FundingDeskAggregatedCollateral]
WHERE AsOfDate = '?'