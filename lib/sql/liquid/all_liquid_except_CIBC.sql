SELECT *
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
WHERE ISR_streamName NOT IN ('ICBCPP_EXT_EQUITY','ICBCIF_EXT_EQUITY')