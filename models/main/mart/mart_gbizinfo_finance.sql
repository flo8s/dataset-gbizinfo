{{ config(materialized='table') }}

{# 財務指標の推移 (法人 × 回次 1 行)。gBizINFO は 1 法人あたり直近 5 期分を持つ。
   period_number は 0 が最新で、数字が大きいほど過去。全法人が 5 期そろうわけでは
   ないので、無い回次の行は作らない。corporate_number で法人マスタと結合できる。 #}
select
    corporate_number,
    name,
    period_number,
    period_end_estimated,
    latest_period_end,
    fiscal_year as latest_period_label,
    net_sales,
    operating_revenue,
    operating_receipts,
    gross_operating_revenue,
    ordinary_revenue,
    net_premiums_written,
    ordinary_income,
    net_income,
    total_assets,
    net_assets,
    capital_stock,
    employee_number
from {{ ref('stg_gbizinfo_finance') }}
