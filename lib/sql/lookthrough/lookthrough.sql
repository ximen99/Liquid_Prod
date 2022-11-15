USE RiskRaw;
WITH LookThrough
AS (
	SELECT O.PositionId AS BCI_ID
		,CASE WHEN o.InstrumentTypeCode IN ('EQY_IDX_SWP')
				--THEN M.MSCI_RM_INDEX_ID 
				THEN ISNULL(O.SwapIndexId, '')
			WHEN o.InstrumentTypeCode IN ('EQY_IDX_OPT')	
				THEN O.Underlying
			ELSE ''
			END AS MSCI_RM_INDEX_ID
		,CASE WHEN o.InstrumentTypeCode IN ('EQY_BSKT_SWP','EQY_SINGLE_NAME_SWP')
				THEN O.ConstituentHoldingGroupName 
			WHEN o.InstrumentTypeCode IN ('EQY_IDX_SWP')	
				--THEN M.BENCHMARK_ID
				THEN ISNULL(left(O.LookThroughNameConstituents, LEN(O.LookThroughNameConstituents)-14),O.ConstituentHoldingGroupName)
			WHEN o.InstrumentTypeCode IN ('EQY_IDX_FUT')	
				THEN O.ExchangeId_Best
			ELSE ''
			END AS BENCHMARK_ID
		,O.InstrumentType AS INSTRUMENT_TYPE
	FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] O
	--LEFT JOIN [MDS_ISR].[mdm].[ENRICHMENT_viwBenchmarkSecurityMap] M on M.SEC_ID = O.SecId
	WHERE O.InstrumentTypeCode IN ('ETF','FF_SWP','EQY_BSKT_SWP','EQY_SINGLE_NAME_SWP','EQY_IDX_SWP','EQY_IDX_OPT','EQY_IDX_FUT')
		AND ((O.SwapLegTypeCode IN ('EQUITY_LEG')) OR (O.SwapLegTypeCode IS NULL))
		AND O.ISR_streamName NOT IN ('SCD_EBSCONST','SCD_ESSCONST')
		AND O.PortfolioCode NOT IN ('E0D0125')
)
SELECT DISTINCT * FROM LookThrough
ORDER BY 4,1