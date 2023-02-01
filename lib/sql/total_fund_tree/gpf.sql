USE RiskRaw;
WITH tmp
     AS (SELECT [POS1].[EFFECTIVE_DATE], 
                POS1.[LOWEST_LEVEL_PORTFOLIO] AS FUND, 
                S1.[SHORT_NAME] AS CORPORATION_NAME, 
                PL2.[PARENT_EDM_ID], 
                S2.INSTRUMENT_TYPE_CODE, 
                S2.[SHORT_NAME], 
                S2.[EDM_INSTRUMENT_ID]
         FROM rpt_SCD.[Master_FN_POSITION] POS1
              LEFT JOIN rpt_SCD.[Master_FN_INSTRUMENT_CONSOLIDATED] S1 ON POS1.[EDM_INSTRUMENT_ID] = S1.[EDM_INSTRUMENT_ID]
              LEFT JOIN rpt_SCD.[Master_FN_PORTFOLIO_LOOKTHROUGH] PL1 ON POS1.[EDM_INSTRUMENT_ID] = PL1.[CHILD_EDM_ID]
              LEFT JOIN rpt_SCD.[Master_FN_POSITION] POS2 ON PL1.[PARENT_EDM_ID] = POS2.[EDM_PORTFOLIO_ID] -- get the portfolios in second layers
              LEFT JOIN rpt_SCD.[Master_FN_INSTRUMENT_CONSOLIDATED] S2 ON POS2.[EDM_INSTRUMENT_ID] = S2.[EDM_INSTRUMENT_ID]
              LEFT JOIN rpt_SCD.[Master_FN_PORTFOLIO_LOOKTHROUGH] PL2 ON POS2.[EDM_INSTRUMENT_ID] = PL2.[CHILD_EDM_ID]
         WHERE [POS1].[EFFECTIVE_DATE] = ?  ------------------DATE FIELD
               AND POS1.[LOWEST_LEVEL_PORTFOLIO] = 'GPF_ABS'
			   -- AND POS1.[LOWEST_LEVEL_PORTFOLIO] = 'E0E0225' -- use this portfolio code before Apr 2021
               AND POS1.portfolio_calculation = 'DWH_IBOR'
               AND S1.INSTRUMENT_TYPE_CODE = 'EQ_CORP_CA'
               AND S2.INSTRUMENT_TYPE_CODE IN('EQ_TRUST', 'PE_EQY', 'EQ_EQY')
              AND [POS2].[EFFECTIVE_DATE] = [POS1].[EFFECTIVE_DATE]
              AND POS2.portfolio_calculation = 'DWH_IBOR')
SELECT [POS].[EFFECTIVE_DATE], 
    tmp.FUND, 
    tmp.CORPORATION_NAME, 
    tmp.SHORT_NAME AS TRUST_NAME, 
    S.[SCD_SEC_ID], 
    S.short_NAME AS Manager_Name, 
    [S].[INSTRUMENT_TYPE_CODE],
    POS.LOCAL_CURRENCY_CODE,
    POS.FX_RATE,
    --POS.[MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV] / 1000000 AS [Market Value (M)]
    POS.[MARKET_VALUE_ACCRUED_INTEREST_LOCAL_NAV] AS LOCAL_Total_Market_Value,
    POS.[MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV] AS BASE_Total_Market_Value
FROM tmp
    LEFT JOIN rpt_SCD.[Master_FN_POSITION] POS ON tmp.PARENT_EDM_ID = POS.EDM_PORTFOLIO_ID
    LEFT JOIN rpt_SCD.[Master_FN_INSTRUMENT_CONSOLIDATED] S ON S.EDM_INSTRUMENT_ID = POS.EDM_INSTRUMENT_ID
WHERE tmp.INSTRUMENT_TYPE_CODE = 'EQ_TRUST'
    --AND [POS].[EFFECTIVE_DATE]='2021-01-15'
    AND POS.portfolio_calculation = 'DWH_IBOR'
    --AND S.[INSTRUMENT_TYPE_CODE] IN('PE_EQY', 'PE_LOAN')
    AND tmp.EFFECTIVE_DATE = pos.EFFECTIVE_DATE
    AND S.INSTRUMENT_TYPE_CODE NOT IN ('CASH','ALM','MMKT_POOL_FUND','EQ_TRUST')
    AND POS.[MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV] !=0
UNION ALL
SELECT [POS].[EFFECTIVE_DATE], 
    tmp.FUND, 
    tmp.CORPORATION_NAME, 
    NULL AS TRUST_NAME, 
    S.[SCD_SEC_ID], 
    S.short_NAME AS Manager_Name, 
    [S].[INSTRUMENT_TYPE_CODE],
    POS.LOCAL_CURRENCY_CODE,
    POS.FX_RATE,
    --POS.[MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV] / 1000000 AS [Market Value (M)]
    POS.[MARKET_VALUE_ACCRUED_INTEREST_LOCAL_NAV] AS LOCAL_Total_Market_Value,
    POS.[MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV] AS BASE_Total_Market_Value
FROM tmp
    LEFT JOIN rpt_SCD.[Master_FN_POSITION] POS ON tmp.EDM_INSTRUMENT_ID = POS.EDM_INSTRUMENT_ID
    LEFT JOIN rpt_SCD.[Master_FN_INSTRUMENT_CONSOLIDATED] S ON S.EDM_INSTRUMENT_ID = POS.EDM_INSTRUMENT_ID
WHERE --tmp.INSTRUMENT_TYPE_CODE = 'PE_EQY'
    -- AND [POS].[EFFECTIVE_DATE]='2021-01-15'
    POS.portfolio_calculation = 'DWH_IBOR'
    AND tmp.EFFECTIVE_DATE = pos.EFFECTIVE_DATE
    AND S.INSTRUMENT_TYPE_CODE NOT IN ('CASH','ALM','MMKT_POOL_FUND','EQ_TRUST')
    AND POS.[MARKET_VALUE_ACCRUED_INTEREST_BASE_NAV] !=0
    AND S.[SCD_SEC_ID] != 'EHAYFING'