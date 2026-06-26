{{ config(materialized='table') }}

{# 届出・認定実績 (届出・認定 1 件 1 行)。corporate_number で法人マスタと結合できる。 #}
select
    corporate_number,
    name,
    title,
    target,
    division,
    issuer,
    certification_date
from {{ ref('stg_gbizinfo_certification') }}
