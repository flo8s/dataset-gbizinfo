{{ config(materialized='table') }}

{# 職場情報 (法人 1 行)。女性活躍推進法・次世代育成支援対策推進法にもとづく公表項目を
   落とさずに出す。mart_gbizinfo_company は平均年齢・残業時間・女性比率の 3 項目しか
   持たない。gBizINFO は 1 項目も届け出ていない法人も名称だけの行として返すため、
   実測値を 1 つ以上報告している法人に絞る。*_scope は対象とする労働者の区分を選んだだけで
   数値が無い行があり、区分だけでは報告とみなさないので絞り込みの判定に入れない。
   corporate_number で法人マスタ・houjin_bangou・mhlw(女性活躍推進企業DB) と結合できる。 #}
select
    corporate_number,
    name,
    avg_age,
    avg_monthly_overtime,
    avg_service_years_scope,
    avg_service_years_male,
    avg_service_years_female,
    avg_service_years_regular,
    female_ratio_scope,
    female_ratio,
    female_managers,
    total_managers,
    round(female_managers * 100.0 / nullif(total_managers, 0), 1)   as female_manager_ratio,
    female_officers,
    total_officers,
    round(female_officers * 100.0 / nullif(total_officers, 0), 1)   as female_officer_ratio,
    childcare_leave_eligible_male,
    childcare_leave_taken_male,
    round(childcare_leave_taken_male * 100.0
          / nullif(childcare_leave_eligible_male, 0), 1)            as childcare_leave_ratio_male,
    childcare_leave_eligible_female,
    childcare_leave_taken_female,
    round(childcare_leave_taken_female * 100.0
          / nullif(childcare_leave_eligible_female, 0), 1)          as childcare_leave_ratio_female
from {{ ref('stg_gbizinfo_workplace') }}
where avg_age is not null
   or avg_monthly_overtime is not null
   or avg_service_years_male is not null
   or avg_service_years_female is not null
   or avg_service_years_regular is not null
   or female_ratio is not null
   or female_managers is not null
   or total_managers is not null
   or female_officers is not null
   or total_officers is not null
   or childcare_leave_eligible_male is not null
   or childcare_leave_taken_male is not null
   or childcare_leave_eligible_female is not null
   or childcare_leave_taken_female is not null
