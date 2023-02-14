SELECT *
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
WHERE ISR_streamName NOT IN ('Hayfin', 'Ares', 'Ext_Antares', 'SCD_Beluga', 'SCD_Minke', 'RANGER_QR_NT','ICBCPP_EXT_EQUITY','ICBCIF_EXT_EQUITY','SCD_EBSCONST','SCD_ESSCONST','UNIT_REALLOCATION')
AND ParentPortfolioCode NOT IN ('EBRONCO','ME170D','ME170SIN','ME170UIN','E0071N','ME0017','ME0044','ME0358','E0074','ME0025','ME173B')
ORDER BY ParentPortfolioCode