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
WHERE ISR_streamName NOT IN ('ICBCPP_EXT_EQUITY','ICBCIF_EXT_EQUITY', 'ECOWEN')
----------------remove after prod implementation----------------
and PositionId not in (
select PositionId FROM [RMRepository].[rmstg].[RmLiquidDerivativeOutput] 
where PortfolioCode like '%riskneust%'
and AssetId  in (select * from b)
)
and PositionId not in (
select PositionId from c where Asset_Class='Client'
)
