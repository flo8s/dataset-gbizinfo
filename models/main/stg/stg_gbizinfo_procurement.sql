{{ config(materialized='view') }}

{# 調達情報 (受注 1 件 1 行)。落札価格は数字以外を除いて bigint 化する。 #}
select
    lpad(trim(corporate_number), 13, '0')                               as corporate_number,
    name,
    title,
    try_cast(regexp_replace(award_price, '[^0-9]', '', 'g') as bigint)  as award_price,
    org_name,
    note,
    try_cast(order_date as date)                                        as order_date
from {{ ref('raw_gbizinfo_procurement') }}
where corporate_number is not null
  and trim(corporate_number) <> ''
