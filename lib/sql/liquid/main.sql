SELECT *
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
WHERE HoldingGroupName NOT IN ('E0040', 'E0041','E0042','E0043','E0080','E0084','RISKPE01','RISKIN01','RISKRR01','E0044')
AND ISR_streamName 
IN ( 
	'SCD_EBS',
	'SCD_EQUITYOPTION',
	'SCD_FUT',
	'SCD_EIS',
	'SCD_FXFWD',
	'SCD_IRS',
	'SCD_LIQUIDS',
	'UNIT_REALLOCATION',
	'UNITIZED_FUND'
	)
AND ParentPortfolioCode NOT LIKE '%HG_%'
AND ParentPortfolioCode NOT IN ('E0071N','ME0017','ME0044','ME0358','E0074','ME0025','ME173B','ME170D','ME170SIN','ME170UIN') 