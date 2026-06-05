{{ config(materialized='table') }}

{# 調達情報 (Chotatsujoho)。1 法人に複数行 (受注 1 件 1 行)。 #}
{% set columns = [
    'corporate_number',
    'name',
    'location',
    'order_date',
    'title',
    'award_price',
    'org_name',
    'note'
] %}

{{ read_gbiz_csv(var('gbiz_procurement_csv'), columns) }}
