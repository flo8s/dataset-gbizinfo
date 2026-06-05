{{ config(materialized='view') }}

{# 補助金情報 (補助金 1 件 1 行)。金額は数字以外を除いて bigint 化する。 #}
select
    lpad(trim(corporate_number), 13, '0')                          as corporate_number,
    name,
    title,
    try_cast(regexp_replace(amount, '[^0-9]', '', 'g') as bigint)  as amount,
    target,
    issuer,
    try_cast(certification_date as date)                           as certification_date
from {{ ref('raw_gbizinfo_subsidy') }}
where corporate_number is not null
  and trim(corporate_number) <> ''
