SET NOCOUNT ON
DECLARE @SQL VARCHAR(MAX)
SET @SQL = '
USE RiskRaw   

DECLARE @POS TABLE(
    MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV decimal(38,12) null
    ,INSTRUMENT_TYPE_CODE varchar(50) null
    ,SHORT_NAME varchar(50) null
    ,EDM_INSTRUMENT_ID varchar(50) null
    ,PORTFOLIO_CALCULATION varchar(25) null
    ,SCD_SEC_ID varchar(50) null
    ,IPS_SECURITY_ID varchar(50) null
    ,LOWEST_LEVEL_PORTFOLIO varchar(50)
    ,SUB_PORTFOLIO_CODE varchar(50)
)

INSERT INTO @POS (
    MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV,
    INSTRUMENT_TYPE_CODE,
    SHORT_NAME,
    EDM_INSTRUMENT_ID,
    PORTFOLIO_CALCULATION,
    SCD_SEC_ID,
    IPS_SECURITY_ID,
    LOWEST_LEVEL_PORTFOLIO,
    SUB_PORTFOLIO_CODE

 

)
SELECT 
    POS1.MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV,
    S1.INSTRUMENT_TYPE_CODE,
    S1.SHORT_NAME,
    S1.EDM_INSTRUMENT_ID,
    PORTFOLIO_CALCULATION,
    S1.SCD_SEC_ID,
    S1.IPS_SECURITY_ID,
    POS1.LOWEST_LEVEL_PORTFOLIO,
    pos1.SUB_PORTFOLIO_CODE


FROM rpt_SCD.[Master_FN_POSITION] POS1
              LEFT JOIN rpt_SCD.[Master_FN_INSTRUMENT_CONSOLIDATED] S1 ON POS1.[EDM_INSTRUMENT_ID] = S1.[EDM_INSTRUMENT_ID]
                        WHERE 
                        --POS1.LOWEST_LEVEL_PORTFOLIO IN (''GPF_ABS'' , ''E0E0225'')
      --                  AND 
                        POS1.EFFECTIVE_DATE = @valuationDate
                        AND POS1.SOURCE = ''SCD_MAIN''
                        AND INSTRUMENT_TYPE_CODE NOT IN (''ALM'', ''CASH'', ''FX_FWD'',''FX_SWP'',''MMKT_POOL_FUND'',''EQY_POOL_FUND'',''EQY_IDX_SWP'',''EQY_SINGLE_NAME_SWP'')
                        AND POS1.PORTFOLIO_CALCULATION = ''DWH_IBOR'';

 

WITH Hierarchy(
    MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV,
    INSTRUMENT_TYPE_CODE,
    SHORT_NAME,
    EDM_INSTRUMENT_ID,
    PORTFOLIO_CALCULATION,
    SCD_SEC_ID,
    IPS_SECURITY_ID,
    LOWEST_LEVEL_PORTFOLIO,
    SUB_PORTFOLIO_CODE,
    Level
    )

 

AS
    (
        SELECT 
                 MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV,
                 INSTRUMENT_TYPE_CODE,
                 SHORT_NAME,
                 EDM_INSTRUMENT_ID,
                 PORTFOLIO_CALCULATION,
                 SCD_SEC_ID,
                 IPS_SECURITY_ID,
                 LOWEST_LEVEL_PORTFOLIO,
                 SUB_PORTFOLIO_CODE,
                 1 as Level

 

            FROM @POS AS FirtIteration
                 Where FirtIteration.LOWEST_LEVEL_PORTFOLIO IN (''GPF_ABS'' , ''E0E0225'')
        UNION ALL
        SELECT 
                 Child.MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV,
                 Child.INSTRUMENT_TYPE_CODE,
                 Child.SHORT_NAME,
                 Child.EDM_INSTRUMENT_ID,
                 Child.PORTFOLIO_CALCULATION,
                 Child.SCD_SEC_ID,
                 Child.IPS_SECURITY_ID,
                 Child.LOWEST_LEVEL_PORTFOLIO,
                 CHILD.SUB_PORTFOLIO_CODE,
                 Parent.Level + 1 as Level
            FROM @POS AS Child
            INNER JOIN Hierarchy AS Parent ON  Parent.SCD_SEC_ID  = Child.LOWEST_LEVEL_PORTFOLIO
    )

 

SELECT DISTINCT * 
FROM Hierarchy   
WHERE SCD_SEC_ID NOT IN (''EHAYFING'',''ECOMPASS'',''EBRONCO'') AND SCD_SEC_ID NOT IN (select LOWEST_LEVEL_PORTFOLIO From Hierarchy)
Order by Level, LOWEST_LEVEL_PORTFOLIO OPTION(MAXRECURSION 32767)'
EXECUTE(@SQL)

