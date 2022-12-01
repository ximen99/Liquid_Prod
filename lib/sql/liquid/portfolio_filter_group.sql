SELECT *
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
WHERE ISR_streamName NOT IN ('Hayfin', 'Ares', 'Ext_Antares', 'SCD_Beluga', 'SCD_Minke', 'RANGER_QR_NT','ICBCPP_EXT_EQUITY','ICBCIF_EXT_EQUITY','SCD_EBSCONST','SCD_ESSCONST','UNIT_REALLOCATION')
AND ParentPortfolioCode != 'EBRONCO'
ORDER BY ParentPortfolioCode