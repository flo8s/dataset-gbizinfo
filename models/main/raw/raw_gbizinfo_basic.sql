{{ config(materialized='table') }}

{# 基本情報 (Kihonjoho) の列順。DownloadTop の CSV ヘッダ順に対応する。 #}
{% set columns = [
    'corporate_number',
    'name',
    'name_kana',
    'name_en',
    'close_date',
    'close_cause',
    'location',
    'postal_code',
    'prefecture_name',
    'prefecture_code',
    'city_name',
    'city_code',
    'street_number',
    'kind',
    'process',
    'correct',
    'status',
    'representative_name',
    'capital_stock',
    'employee_number',
    'company_scale_male',
    'company_scale_female',
    'business_summary',
    'company_url',
    'founding_year',
    'business_items',
    'date_of_establishment',
    'qualification_grade',
    'qualification_business_items',
    'update_date'
] %}

{{ read_gbiz_csv(var('gbiz_basic_csv'), columns) }}
