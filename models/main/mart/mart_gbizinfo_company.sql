{{ config(materialized='table') }}

{# 法人 1 行の集約。基本属性に補助金・調達の集計と最新財務・職場指標を結合する。
   corporate_number で houjin_bangou(国税庁法人番号)・lg-code と結合できる。 #}
with subsidy_agg as (
    select
        corporate_number,
        count(*)      as subsidy_count,
        sum(amount)   as subsidy_total_amount
    from {{ ref('stg_gbizinfo_subsidy') }}
    group by corporate_number
),

procurement_agg as (
    select
        corporate_number,
        count(*)          as procurement_count,
        sum(award_price)  as procurement_total_award
    from {{ ref('stg_gbizinfo_procurement') }}
    group by corporate_number
),

finance_latest as (
    -- 回次(period_number) 0 が最新で、法人ごとに一意かつ全法人が保有する。
    -- ウィンドウ関数 + 複数 LEFT JOIN は DuckDB の最適化で内部エラーになるため、
    -- 単純なフィルタで最新行を選ぶ。
    select
        corporate_number,
        fiscal_year,
        net_sales,
        ordinary_income,
        net_income,
        total_assets,
        net_assets
    from {{ ref('stg_gbizinfo_finance') }}
    where period_number = 0
)

select
    b.corporate_number,
    b.name,
    b.capital_stock,
    b.employee_number,
    b.date_of_establishment,
    b.founding_year,
    b.business_summary,
    b.business_items,
    b.representative_name,
    b.company_url,
    coalesce(s.subsidy_count, 0)      as subsidy_count,
    s.subsidy_total_amount,
    coalesce(p.procurement_count, 0)  as procurement_count,
    p.procurement_total_award,
    f.fiscal_year                     as latest_fiscal_year,
    f.net_sales                       as latest_net_sales,
    f.ordinary_income                 as latest_ordinary_income,
    f.net_income                      as latest_net_income,
    f.total_assets                    as latest_total_assets,
    f.net_assets                      as latest_net_assets,
    w.avg_age,
    w.avg_monthly_overtime,
    w.female_ratio
from {{ ref('stg_gbizinfo_basic') }} b
left join subsidy_agg s     on b.corporate_number = s.corporate_number
left join procurement_agg p on b.corporate_number = p.corporate_number
left join finance_latest f  on b.corporate_number = f.corporate_number
left join {{ ref('stg_gbizinfo_workplace') }} w on b.corporate_number = w.corporate_number
