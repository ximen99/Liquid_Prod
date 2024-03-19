SELECT FundName,sum(PosMarketValueBase) MV
  FROM [RiskRaw].[historical_ExternalPosition].[ECP_ABC]
  where PosDate = (select top 1 PosDate from [RiskRaw].[historical_ExternalPosition].[ECP_ABC] order by PosDate desc)
  and FundName like 'ECP Credit Strategies%'
  group by FundName