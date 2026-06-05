{# gBizINFO データダウンロードの全件 CSV を読み込む。
   DownloadTop が出力する CSV は UTF-8(BOM 付き)・ヘッダ行ありで、列順は固定。
   日本語ヘッダを英語名へ読み替えるため columns を明示する (header=true で
   先頭行を読み飛ばし、ここで与えた名前と型を採用する)。
   名称・件名フィールドにカンマや二重引用符が含まれるため quote / escape を指定する。
   url には main.py がダウンロードした CSV の絶対パスを渡す。 #}
{% macro read_gbiz_csv(url, columns) %}
select *
from read_csv(
    '{{ url }}',
    header=true,
    quote='"',
    escape='"',
    columns={
    {%- for name in columns %}
        '{{ name }}': 'VARCHAR'{{ "," if not loop.last }}
    {%- endfor %}
    }
)
{% endmacro %}
