{{ config(materialized='table') }}

{# 補助金交付実績 (補助金 1 件 1 行)。corporate_number で法人マスタと結合できる。 #}
select
    corporate_number,
    name,
    title,
    amount,
    target,
    issuer,
    certification_date
from {{ ref('stg_gbizinfo_subsidy') }}
