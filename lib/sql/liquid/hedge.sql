SELECT *
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
WHERE ISR_streamName 
IN ( 
	'SCD_EBS',
	'SCD_EQUITYOPTION',
	'SCD_EIS',
	'SCD_FUT',
	'SCD_FXFWD',
	'SCD_IRS',
	'SCD_LIQUIDS',
	'UNIT_REALLOCATION',
	'UNITIZED_FUND'
	)
AND ParentPortfolioCode LIKE '%HG_%'