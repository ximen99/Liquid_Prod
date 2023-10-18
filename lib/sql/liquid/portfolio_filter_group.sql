SELECT *
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
WHERE ISR_streamName NOT IN ('Hayfin', 'Ares', 'Ext_Antares', 'SCD_Beluga', 'SCD_Minke', 'RANGER_QR_NT','ICBCPP_EXT_EQUITY','ICBCIF_EXT_EQUITY','SCD_EBSCONST','SCD_ESSCONST','UNIT_REALLOCATION')
AND ParentPortfolioCode NOT IN ('EBRONCO','E0071N','ME0017','ME0044','ME0358','E0074','ME0025','ME173B','ME170D','ME170UIN','E0355','E0041','E0042','E0044', 'ECOWEN')
AND PositionId <> 'E0D0125_EDPT0125_70669603_1'
ORDER BY ParentPortfolioCode