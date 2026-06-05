{{ config(materialized='view') }}

{# 財務情報 (事業年度・回次ごと 1 行)。主要指標のみ抽出して数値化する。
   回次 (period_number) は 0 が最新で、数字が大きいほど過去。 #}
select
    lpad(trim(corporate_number), 13, '0')                          as corporate_number,
    name,
    accounting_standards,
    fiscal_year,
    try_cast(period_number as integer)                             as period_number,
    try_cast(regexp_replace(net_sales, '[^0-9]', '', 'g') as bigint)        as net_sales,
    try_cast(regexp_replace(ordinary_income, '[^0-9-]', '', 'g') as bigint) as ordinary_income,
    try_cast(regexp_replace(net_income, '[^0-9-]', '', 'g') as bigint)      as net_income,
    try_cast(regexp_replace(total_assets, '[^0-9]', '', 'g') as bigint)     as total_assets,
    try_cast(regexp_replace(net_assets, '[^0-9-]', '', 'g') as bigint)      as net_assets,
    try_cast(regexp_replace(capital_stock, '[^0-9]', '', 'g') as bigint)    as capital_stock,
    try_cast(employee_number as integer)                           as employee_number
from {{ ref('raw_gbizinfo_finance') }}
where corporate_number is not null
  and trim(corporate_number) <> ''
