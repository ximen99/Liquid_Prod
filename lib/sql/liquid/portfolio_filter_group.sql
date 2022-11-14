SELECT *
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
WHERE ISR_streamName 
IN ( 
	'SCD_EBS',
	'SCD_FUT',
	'SCD_EIS',
	'SCD_FXFWD',
	'SCD_IRS',
	'SCD_LIQUIDS',
	'UNITIZED_FUND'
	)