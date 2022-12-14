SELECT *
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
WHERE ISR_streamName 
IN ( 
	'ICBCIF_EXT_EQUITY',
	'ICBCPP_EXT_EQUITY',
	'SCD_EBS',
	'SCD_EBSCONST',
	'SCD_EIS', 
	'SCD_EQUITYOPTION',
	'SCD_ESSCONST',
	'SCD_FUT',
	'SCD_FXFWD',
	'SCD_IRS',
	'SCD_LIQUIDS',
	'UNIT_REALLOCATION',
	'UNITIZED_FUND'
	)
AND HoldingGroupName IN ('E0040', 'E0041','E0042','E0043','E0080','E0084','RISKPE01','RISKIN01','RISKRR01','E0044')