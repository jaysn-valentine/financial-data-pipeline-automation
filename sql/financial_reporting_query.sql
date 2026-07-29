/*
Public portfolio version of the reporting query.
Update the example source paths, data source name, field names, and filter
values for your own environment before running it.
*/

WITH StrategyA AS (
    SELECT *
    FROM OPENROWSET(
        BULK 'raw/holdings/strategy_a/YYYY/MM/DD/*',
        DATA_SOURCE = 'EXTERNAL_DATA_SOURCE',
        FORMAT = 'PARQUET'
    ) AS H
    WHERE H.TICKER IN ('FUND_A', 'FUND_B', 'FUND_C')
),
StrategyB AS (
    SELECT *
    FROM OPENROWSET(
        BULK 'raw/holdings/strategy_b/YYYY/MM/DD/*',
        DATA_SOURCE = 'EXTERNAL_DATA_SOURCE',
        FORMAT = 'PARQUET'
    ) AS H
    WHERE H.TICKER IN ('FUND_A', 'FUND_B', 'FUND_C')
),
CombinedHoldings AS (
    SELECT *, 'Strategy A' AS ACCOUNT_TYPE FROM StrategyA
    UNION ALL
    SELECT *, 'Strategy B' AS ACCOUNT_TYPE FROM StrategyB
),
AccountMaster AS (
    SELECT ACCOUNT_ID, REPRESENTATIVE_CODE, MANAGER_CODE
    FROM OPENROWSET(
        BULK 'raw/accounts/master/YYYY/MM/DD/*',
        DATA_SOURCE = 'EXTERNAL_DATA_SOURCE',
        FORMAT = 'PARQUET'
    ) AS A
),
AccountAttributes AS (
    SELECT ACCOUNT_ID, CUSTODIAN_FIELD, PROGRAM_FLAG, MANAGEMENT_FLAG
    FROM OPENROWSET(
        BULK 'raw/accounts/attributes/YYYY/MM/DD/*',
        DATA_SOURCE = 'EXTERNAL_DATA_SOURCE',
        FORMAT = 'PARQUET'
    ) AS F
),
CustodianData AS (
    SELECT ACCOUNT_ID, CUSTODIAN_CODE
    FROM OPENROWSET(
        BULK 'curated/holdings/*',
        DATA_SOURCE = 'EXTERNAL_DATA_SOURCE',
        FORMAT = 'PARQUET'
    ) AS C
)
SELECT DISTINCT
    H.ACCOUNT_ID,
    H.ACCOUNT_NAME,
    H.OPEN_DATE,
    H.UNITS,
    H.TICKER,
    H.CUSIP,
    H.COST,
    H.MARKET_VALUE,
    H.DESCRIPTION,
    H.ACCOUNT_TYPE,
    A.REPRESENTATIVE_CODE,
    A.MANAGER_CODE,
    C.CUSTODIAN_CODE,
    F.CUSTODIAN_FIELD,
    F.PROGRAM_FLAG,
    F.MANAGEMENT_FLAG
FROM CombinedHoldings AS H
LEFT JOIN AccountMaster AS A
    ON UPPER(TRIM(H.ACCOUNT_ID)) = UPPER(TRIM(A.ACCOUNT_ID))
LEFT JOIN AccountAttributes AS F
    ON UPPER(TRIM(H.ACCOUNT_ID)) = UPPER(TRIM(F.ACCOUNT_ID))
LEFT JOIN CustodianData AS C
    ON UPPER(TRIM(H.ACCOUNT_ID)) = UPPER(TRIM(C.ACCOUNT_ID))
WHERE TRY_CAST(A.REPRESENTATIVE_CODE AS INT) < 99
  AND (F.CUSTODIAN_FIELD IS NULL OR UPPER(TRIM(F.CUSTODIAN_FIELD)) <> 'EXCLUDE')
  AND (F.PROGRAM_FLAG IS NULL OR UPPER(TRIM(F.PROGRAM_FLAG)) <> 'N')
ORDER BY H.ACCOUNT_ID, H.TICKER;
