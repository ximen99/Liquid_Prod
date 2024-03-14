SELECT * 
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
WHERE  ParentPortfolioCode IN ('EDPL0125', 'EDPLSKAN', 'EDPTHETI')
AND ISR_streamName <> 'SCD_Beluga'