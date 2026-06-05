{{ config(materialized='view') }}

{# 基本情報を正規化する。corporate_number は houjin_bangou と結合できるよう
   13 桁 VARCHAR に揃える。基本情報は 1 法人 1 行のはずだが、念のため
   update_date が新しい行を採用して重複を除く。 #}
select
    lpad(trim(corporate_number), 13, '0')             as corporate_number,
    name,
    name_kana,
    name_en,
    representative_name,
    try_cast(capital_stock as bigint)                 as capital_stock,
    try_cast(employee_number as integer)              as employee_number,
    try_cast(date_of_establishment as date)           as date_of_establishment,
    try_cast(founding_year as integer)                as founding_year,
    business_summary,
    business_items,
    company_url,
    qualification_grade,
    prefecture_name,
    prefecture_code,
    city_name,
    city_code,
    try_cast(update_date as date)                     as update_date
from {{ ref('raw_gbizinfo_basic') }}
where corporate_number is not null
  and trim(corporate_number) <> ''
qualify row_number() over (
    partition by lpad(trim(corporate_number), 13, '0')
    order by try_cast(update_date as date) desc nulls last
) = 1
