{{ config(materialized='view') }}

{# 特許/意匠/商標 (1 件 1 行)。出願年月日を date 化し、特許/意匠/商標で分かれている
   分類コード・分類名を rights_type に応じて 1 列へ統合する。 #}
select
    lpad(trim(corporate_number), 13, '0')      as corporate_number,
    name,
    rights_type,
    registration_number,
    title,
    coalesce(
        nullif(patent_fi_class_code, ''),
        nullif(design_class_code, ''),
        nullif(trademark_class_code, '')
    )                                          as classification_code,
    coalesce(
        nullif(patent_fi_class_name, ''),
        nullif(design_class_name, ''),
        nullif(trademark_class_name, '')
    )                                          as classification,
    document_url,
    try_cast(application_date as date)         as application_date
from {{ ref('raw_gbizinfo_patent') }}
where corporate_number is not null
  and trim(corporate_number) <> ''
