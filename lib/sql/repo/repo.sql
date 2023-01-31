SELECT O.RiskDate AS Valuation_date
	  ,O.UnderlyingCUSIP AS BCI_underlyingCUSIP
      ,O.CounterParty AS counterparty
      ,CASE WHEN O.InstrumentTypeCode IN ('REPO_SBB','REPO')
				THEN O.UnderlyingBondParAmount * -1
			WHEN O.InstrumentTypeCode IN ('REPO_BSB','REV_REPO')
				THEN O.UnderlyingBondParAmount
			END
			AS BCI_underlyingParAmount
	 ,O.InstrumentTypeDesc
	 ,CASE WHEN O.InstrumentTypeCode IN ('REPO_SBB','REPO')
				THEN 'REPO'
			WHEN O.InstrumentTypeCode IN ('REPO_BSB','REV_REPO')
				THEN 'RR'
			END 
			AS InstrumentTypeCode
	--,O.RepoTradeDate
	--,O.RepoSettleDate
	--,O.MaturityDate

FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] O
WHERE O.ISR_streamName = 'SCD_LIQUIDS'
AND O.InstrumentTypeCode IN  ('REPO', 'REV_REPO', 'REPO_SBB', 'REPO_BSB')
AND O.RiskDate >= O.RepoSettleDate
ORDER BY 6 DESC
--, 8,3,2 ASC