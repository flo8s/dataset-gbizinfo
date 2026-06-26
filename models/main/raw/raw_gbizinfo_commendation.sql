{{ config(materialized='table') }}

{# 表彰情報 (Hyoshojoho)。1 法人に複数行 (表彰 1 件 1 行)。 #}
{% set columns = [
    'corporate_number',
    'name',
    'location',
    'certification_date',
    'title',
    'target',
    'division',
    'issuer',
    'note'
] %}

{{ read_gbiz_csv(var('gbiz_commendation_csv'), columns) }}
