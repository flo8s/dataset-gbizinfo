{{ config(materialized='view') }}

{# 職場情報 (1 法人 1 行)。女性活躍・両立支援の指標を数値化する。
   範囲区分 (A-D 等) の列は元の文字列のまま残す。 #}
select
    lpad(trim(corporate_number), 13, '0')              as corporate_number,
    try_cast(avg_age as double)                        as avg_age,
    try_cast(avg_monthly_overtime as double)           as avg_monthly_overtime,
    try_cast(female_ratio as double)                   as female_ratio,
    female_ratio_range,
    try_cast(avg_service_years_male as double)         as avg_service_years_male,
    try_cast(avg_service_years_female as double)       as avg_service_years_female,
    try_cast(avg_service_years_regular as double)      as avg_service_years_regular,
    try_cast(female_managers as integer)               as female_managers,
    try_cast(total_managers as integer)                as total_managers,
    try_cast(female_officers as integer)               as female_officers,
    try_cast(total_officers as integer)                as total_officers
from {{ ref('raw_gbizinfo_workplace') }}
where corporate_number is not null
  and trim(corporate_number) <> ''
qualify row_number() over (
    partition by lpad(trim(corporate_number), 13, '0')
    order by try_cast(avg_age as double) desc nulls last
) = 1
