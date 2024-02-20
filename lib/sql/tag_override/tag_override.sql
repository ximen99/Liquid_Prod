SELECT
	RiskDate,
	InstrumentTypeDesc,
	securityName,
	CounterParty,
	PositionId,
	ExchangeId_Best,
	ExchangeId_BestType,
	MaturityDate,
	COUNT(PositionId) [Count of PositionId],
	SUM(Amount) [Sum of Amount],
	SUM(BaseTotalMarketValue) [Sum of BaseTotalMarketValue],
	PriceCcyCode,
	EntryPrice,
	LocalFuturePrice,
	PricedSecurityName

FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
WHERE ISR_streamName NOT IN ('Hayfin', 'Ares', 'Ext_Antares', 'SCD_Beluga', 'SCD_Minke', 'RANGER_QR_NT','SCD_EBSCONST','SCD_ESSCONST')
AND InstrumentTypeDesc LIKE '%Future%' -- IN ('Bond Future','Equity Index Future','Money Market Future')
AND MaturityDate > RiskDate
AND InstrumentTypeDesc != 'Money Market Future'
GROUP BY RiskDate,
	InstrumentTypeDesc,
	securityName,
	CounterParty,
	PositionId,
	ExchangeId_Best,
	ExchangeId_BestType,
	MaturityDate,
	PositionId,
	Amount,
	BaseTotalMarketValue,
	PriceCcyCode,
	EntryPrice,
	LocalFuturePrice,
	PricedSecurityName
ORDER BY securityName, InstrumentTypeDesc, PositionId