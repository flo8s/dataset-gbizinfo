{{ config(materialized='table') }}

{# 財務情報 (Zaimujoho)。1 法人に複数行 (事業年度・回次ごと)。
   金額は別カラムで単位 (JPY 等) を持つ。 #}
{% set columns = [
    'corporate_number',
    'name',
    'location',
    'accounting_standards',
    'fiscal_year',
    'period_number',
    'net_sales',
    'net_sales_unit',
    'operating_revenue',
    'operating_revenue_unit',
    'operating_income',
    'operating_income_unit',
    'gross_operating_revenue',
    'gross_operating_revenue_unit',
    'ordinary_revenue',
    'ordinary_revenue_unit',
    'net_premiums_written',
    'net_premiums_written_unit',
    'ordinary_income',
    'ordinary_income_unit',
    'net_income',
    'net_income_unit',
    'capital_stock',
    'capital_stock_unit',
    'net_assets',
    'net_assets_unit',
    'total_assets',
    'total_assets_unit',
    'employee_number',
    'employee_number_unit',
    'major_shareholder1',
    'shareholding_ratio1',
    'major_shareholder2',
    'shareholding_ratio2',
    'major_shareholder3',
    'shareholding_ratio3',
    'major_shareholder4',
    'shareholding_ratio4',
    'major_shareholder5',
    'shareholding_ratio5'
] %}

{{ read_gbiz_csv(var('gbiz_finance_csv'), columns) }}
