{{ config(materialized='table') }}

{# 届出・認定情報 (TodokedeNinteijoho)。1 法人に複数行 (届出・認定 1 件 1 行)。 #}
{% set columns = [
    'corporate_number',
    'name',
    'location',
    'certification_date',
    'title',
    'target',
    'division',
    'issuer'
] %}

{{ read_gbiz_csv(var('gbiz_certification_csv'), columns) }}
