{{ config(materialized='view') }}

{# 職場情報 (1 法人 1 行)。女性活躍・両立支援の指標を数値化する。
   *_scope は数値の範囲ではなく、その指標が対象とする労働者の区分で、文字列のまま残す。
   avg_service_years_scope は 正社員 / その他 / 対象とする労働者すべて / 基幹的な職種、
   female_ratio_scope は 正社員 / その他 / 基幹的な職種。 #}
select
    lpad(trim(corporate_number), 13, '0')                as corporate_number,
    name,
    try_cast(avg_age as double)                          as avg_age,
    try_cast(avg_monthly_overtime as double)             as avg_monthly_overtime,
    try_cast(female_ratio as double)                     as female_ratio,
    nullif(trim(female_ratio_range), '')                 as female_ratio_scope,
    nullif(trim(avg_service_years_range), '')            as avg_service_years_scope,
    try_cast(avg_service_years_male as double)           as avg_service_years_male,
    try_cast(avg_service_years_female as double)         as avg_service_years_female,
    try_cast(avg_service_years_regular as double)        as avg_service_years_regular,
    try_cast(female_managers as integer)                 as female_managers,
    try_cast(total_managers as integer)                  as total_managers,
    try_cast(female_officers as integer)                 as female_officers,
    try_cast(total_officers as integer)                  as total_officers,
    try_cast(childcare_leave_eligible_male as integer)   as childcare_leave_eligible_male,
    try_cast(childcare_leave_taken_male as integer)      as childcare_leave_taken_male,
    try_cast(childcare_leave_eligible_female as integer) as childcare_leave_eligible_female,
    try_cast(childcare_leave_taken_female as integer)    as childcare_leave_taken_female
from {{ ref('raw_gbizinfo_workplace') }}
where corporate_number is not null
  and trim(corporate_number) <> ''
qualify row_number() over (
    partition by lpad(trim(corporate_number), 13, '0')
    order by try_cast(avg_age as double) desc nulls last
) = 1
