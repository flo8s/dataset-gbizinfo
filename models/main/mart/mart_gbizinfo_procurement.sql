{{ config(materialized='table') }}

{# 国の調達 (受注) 実績 (受注 1 件 1 行)。corporate_number で法人マスタと結合できる。 #}
select
    corporate_number,
    name,
    title,
    award_price,
    org_name,
    note,
    order_date
from {{ ref('stg_gbizinfo_procurement') }}
