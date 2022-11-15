USE RiskRaw;
WITH IndexCSV
AS (
	SELECT 
		CASE WHEN O.InstrumentTypeCode IN ('EQY_IDX_SWP')
				--THEN M.MSCI_RM_INDEX_ID 
				THEN O.SwapIndexId 
			WHEN O.InstrumentTypeCode IN ('ETF','EQY_IDX_FUT')	
				THEN O.PricedSecurityName
			ELSE ''
			END AS MSCI_RM_INDEX_ID
		,CASE WHEN O.InstrumentTypeCode IN ('EQY_IDX_SWP')
				--THEN M.INDEX_NAME 
				THEN O.Underlying 
			WHEN O.InstrumentTypeCode IN ('ETF')	
				THEN O.ExchangeId_ISIN
			WHEN O.InstrumentTypeCode IN ('EQY_IDX_FUT')	
				THEN O.ExchangeId_Best
			ELSE ''
			END AS INDEX_NAME
		,CASE WHEN o.InstrumentTypeCode IN ('EQY_IDX_SWP')	
				--THEN M.BENCHMARK_ID
				THEN left(O.LookThroughNameConstituents, LEN(O.LookThroughNameConstituents)-14
				)
			ELSE ''
			END AS BENCHMARK_ID
		,O.InstrumentType AS INSTRUMENT_TYPE
		,CONCAT('CUBE_',CASE WHEN O.InstrumentTypeCode IN ('EQY_IDX_SWP')
				--THEN M.MSCI_RM_INDEX_ID 
				THEN O.SwapIndexId 
			WHEN O.InstrumentTypeCode IN ('ETF','EQY_IDX_FUT')	
				THEN O.PricedSecurityName
			ELSE ''
			END) AS PRICED_SECURITY_NAME

	FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] O
	--LEFT JOIN [MDS_ISR].[mdm].[ENRICHMENT_viwBenchmarkSecurityMap] M on M.SEC_ID = O.SecId
	WHERE O.InstrumentTypeCode IN ('ETF','EQY_IDX_SWP','EQY_IDX_FUT')
		AND ((O.SwapLegTypeCode IN ('EQUITY_LEG')) OR (O.SwapLegTypeCode IS NULL))
		AND O.ISR_streamName NOT IN ('SCD_EBSCONST','SCD_ESSCONST')
)
SELECT DISTINCT * FROM IndexCSV 
WHERE MSCI_RM_INDEX_ID IS NOT NULL ------Excludes Indices not required for the data
ORDER BY 4,1
