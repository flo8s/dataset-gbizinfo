{{ config(materialized='view') }}

{# 届出・認定情報 (届出・認定 1 件 1 行)。証明日を date 化する。 #}
select
    lpad(trim(corporate_number), 13, '0')  as corporate_number,
    name,
    title,
    target,
    division,
    issuer,
    try_cast(certification_date as date)   as certification_date
from {{ ref('raw_gbizinfo_certification') }}
where corporate_number is not null
  and trim(corporate_number) <> ''
