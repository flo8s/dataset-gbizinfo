{{ config(materialized='table') }}

{# 特許情報 (Tokkyojoho)。1 法人に複数行 (特許/意匠/商標 1 件 1 行)。約 1.2GB と重いため
   月次 full ビルドでのみ取得する (main.py の FULL_ONLY 種別)。 #}
{% set columns = [
    'corporate_number',
    'name',
    'location',
    'rights_type',
    'registration_number',
    'application_date',
    'patent_fi_class_code',
    'patent_fi_class_name',
    'patent_fterm_theme_code',
    'design_class_code',
    'design_class_name',
    'trademark_class_code',
    'trademark_class_name',
    'title',
    'document_url'
] %}

{{ read_gbiz_csv(var('gbiz_patent_csv'), columns) }}
