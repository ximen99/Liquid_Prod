with a as
(
SELECT 
(select top 1 PORTFOLIO_ASSET_CLASS from RiskRaw.rpt_SCD.Master_FN_PORTFOLIO_CONSOLIDATED where SCD_PORTFOLIO_CODE = r.portfoliocode) as Asset_Class
,
(select top 1 FUND_TYPE_CODE from RiskRaw.rpt_SCD.Master_FN_PORTFOLIO_CONSOLIDATED where SCD_PORTFOLIO_CODE = r.portfoliocode) as Fund_type
,
*
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] as r 
WHERE ISR_streamName NOT IN ('ICBCPP_EXT_EQUITY','ICBCIF_EXT_EQUITY') 
and InstrumentTypeDesc = 'Money Market Pool Fund' 
),
b as
(
select 
CONCAT('RISKNEUST_',AssetId) as new_id
from a where Asset_Class='Client'
),
c as
(
SELECT 
(select top 1 PORTFOLIO_ASSET_CLASS from RiskRaw.rpt_SCD.Master_FN_PORTFOLIO_CONSOLIDATED where SCD_PORTFOLIO_CODE = r.portfoliocode) as Asset_Class
,
(select top 1 FUND_TYPE_CODE from RiskRaw.rpt_SCD.Master_FN_PORTFOLIO_CONSOLIDATED where SCD_PORTFOLIO_CODE = r.portfoliocode) as Fund_type
,
*
FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] as r
WHERE ISR_streamName NOT IN ('ICBCPP_EXT_EQUITY','ICBCIF_EXT_EQUITY') 
and InstrumentTypeDesc = 'Money Market Pool Fund' 
)
----------------remove after prod implementation----------------
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
	'SCD_FXOPTION',
	'UNIT_REALLOCATION',
	'UNITIZED_FUND'
	)
AND ParentPortfolioCode NOT LIKE '%HG_%'
AND ParentPortfolioCode NOT IN ('EBRONCO','E0071N','ME0017','ME0044','ME0358','E0074','ME0025','ME173B','ME170D','ME170UIN','E0355','E0041','E0042','E0044', 'ECOWEN')
AND PositionId <> 'E0D0125_EDPT0125_70669603_1'
----------------remove after prod implementation----------------
and PositionId not in (
select PositionId FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
where PortfolioCode like '%riskneust%'
and AssetId  in (select * from b)
)
and PositionId not in (
select PositionId from c where Asset_Class='Client'
)

