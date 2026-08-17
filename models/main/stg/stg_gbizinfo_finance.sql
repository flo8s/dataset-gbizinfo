{{ config(materialized='view') }}

{# 財務情報 (事業年度・回次ごと 1 行)。主要指標のみ抽出して数値化する。
   回次 (period_number) は 0 が最新で、数字が大きいほど過去。

   fiscal_year は法人ごとに 1 つしか無く、回次が違っても同じ値が入る。中身は
   「第20期（自 2025年４月１日 至 2026年３月31日）」のような最新期のラベルで、
   行ごとの年度ではない。時系列として扱えるよう、ラベルの「至」以降から最新期の
   期末日 (latest_period_end) を取り出し、そこから回次分をさかのぼった期末日を
   period_end_estimated として持たせる。 #}
with parsed as (
    select
        *,
        -- 全角数字を半角へ、「元年」を「1年」へ寄せてから期末の側を取り出す。
        -- 期末の書き出しは「至 ...」と「...から ...まで」の 2 通りあり、
        -- 和暦 (令和・平成・昭和) 表記が 5% ほど混ざる。
        regexp_extract(
            replace(
                translate(fiscal_year, '０１２３４５６７８９', '0123456789'),
                '元年', '1年'
            ),
            '(?:至|から)(.*)', 1
        ) as period_end_text
    from {{ ref('raw_gbizinfo_finance') }}
),

dated as (
    select
        *,
        try_cast(make_date(
            case regexp_extract(period_end_text, '(令和|平成|昭和)', 1)
                when '令和' then 2018
                when '平成' then 1988
                when '昭和' then 1925
                else 0
            end + try_cast(regexp_extract(period_end_text, '([0-9]{1,4})年', 1) as integer),
            try_cast(regexp_extract(period_end_text, '年[^0-9]*([0-9]{1,2})月', 1) as integer),
            try_cast(regexp_extract(period_end_text, '月[^0-9]*([0-9]{1,2})日', 1) as integer)
        ) as date) as latest_period_end
    from parsed
)

select
    lpad(trim(corporate_number), 13, '0')                          as corporate_number,
    name,
    accounting_standards,
    fiscal_year,
    latest_period_end,
    cast(latest_period_end
        - to_years(try_cast(period_number as integer)) as date)    as period_end_estimated,
    try_cast(period_number as integer)                             as period_number,
    try_cast(regexp_replace(net_sales, '[^0-9]', '', 'g') as bigint)        as net_sales,
    -- 銀行・保険・鉄道などは売上高の欄を使わず、営業収益/経常収益/正味収入保険料で
    -- 収益を報告する。売上高だけを見ると収益が空に見えるので併せて持つ。
    try_cast(regexp_replace(operating_revenue, '[^0-9]', '', 'g') as bigint) as operating_revenue,
    try_cast(regexp_replace(ordinary_revenue, '[^0-9]', '', 'g') as bigint)  as ordinary_revenue,
    try_cast(regexp_replace(net_premiums_written, '[^0-9]', '', 'g') as bigint)
                                                                   as net_premiums_written,
    try_cast(regexp_replace(ordinary_income, '[^0-9-]', '', 'g') as bigint) as ordinary_income,
    try_cast(regexp_replace(net_income, '[^0-9-]', '', 'g') as bigint)      as net_income,
    try_cast(regexp_replace(total_assets, '[^0-9]', '', 'g') as bigint)     as total_assets,
    try_cast(regexp_replace(net_assets, '[^0-9-]', '', 'g') as bigint)      as net_assets,
    try_cast(regexp_replace(capital_stock, '[^0-9]', '', 'g') as bigint)    as capital_stock,
    try_cast(employee_number as integer)                           as employee_number
from dated
where corporate_number is not null
  and trim(corporate_number) <> ''
