{{ config(materialized='view') }}

{# 表彰情報 (表彰 1 件 1 行)。証明日を date 化する。 #}
select
    lpad(trim(corporate_number), 13, '0')  as corporate_number,
    name,
    title,
    target,
    division,
    issuer,
    note,
    try_cast(certification_date as date)   as certification_date
from {{ ref('raw_gbizinfo_commendation') }}
where corporate_number is not null
  and trim(corporate_number) <> ''
