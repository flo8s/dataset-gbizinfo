{{ config(materialized='table') }}

{# 特許・意匠・商標の登録実績 (1 件 1 行)。corporate_number で法人マスタと結合できる。 #}
select
    corporate_number,
    name,
    rights_type,
    registration_number,
    title,
    classification,
    classification_code,
    document_url,
    application_date
from {{ ref('stg_gbizinfo_patent') }}
