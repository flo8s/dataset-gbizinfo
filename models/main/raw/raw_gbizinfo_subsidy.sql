{{ config(materialized='table') }}

{# 補助金情報 (Hojokinjoho)。1 法人に複数行 (補助金 1 件 1 行)。 #}
{% set columns = [
    'corporate_number',
    'name',
    'location',
    'certification_date',
    'title',
    'amount',
    'target',
    'issuer'
] %}

{{ read_gbiz_csv(var('gbiz_subsidy_csv'), columns) }}
