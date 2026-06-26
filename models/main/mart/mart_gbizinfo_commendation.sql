{{ config(materialized='table') }}

{# 表彰実績 (表彰 1 件 1 行)。corporate_number で法人マスタと結合できる。 #}
select
    corporate_number,
    name,
    title,
    target,
    division,
    issuer,
    certification_date
from {{ ref('stg_gbizinfo_commendation') }}
