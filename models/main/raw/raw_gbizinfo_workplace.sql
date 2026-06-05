{{ config(materialized='table') }}

{# 職場情報 (Shokubajoho)。女性活躍・両立支援に関する指標。1 法人 1 行。 #}
{% set columns = [
    'corporate_number',
    'name',
    'location',
    'avg_service_years_range',
    'avg_service_years_male',
    'avg_service_years_female',
    'avg_service_years_regular',
    'avg_age',
    'avg_monthly_overtime',
    'female_ratio_range',
    'female_ratio',
    'female_managers',
    'total_managers',
    'female_officers',
    'total_officers',
    'childcare_leave_eligible_male',
    'childcare_leave_eligible_female',
    'childcare_leave_taken_male',
    'childcare_leave_taken_female'
] %}

{{ read_gbiz_csv(var('gbiz_workplace_csv'), columns) }}
