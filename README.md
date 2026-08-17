# dataset-gbizinfo

経済産業省 gBizINFO の法人活動情報を取得し、DuckLake (SQLite カタログ + R2) として Queria に公開するデータセット。
法人番号 (corporate_number) をキーに国税庁法人番号 (dataset-houjin-bangou) や
全国地方公共団体コード (dataset-lg-code) と結合できる。

## 収録データ

gBizINFO の「データダウンロード」から取得した 8 種別の全件データ:

- 基本情報 (資本金・従業員数・設立年・事業概要・業種)
- 補助金交付実績
- 国の調達 (受注) 実績
- 財務情報
- 職場情報 (女性活躍・両立支援の指標)
- 表彰実績
- 届出・認定実績
- 特許・意匠・商標 (登録実績)

公開 mart:

- `mart_gbizinfo_company` — 法人 1 行の活動サマリ (基本属性 + 補助金/調達集計 + 最新財務 + 職場指標)
- `mart_gbizinfo_finance` — 財務指標の推移 (法人 × 回次 1 行・1 法人あたり直近 5 期まで)
- `mart_gbizinfo_subsidy` — 補助金交付実績 (1 件 1 行)
- `mart_gbizinfo_procurement` — 調達 (受注) 実績 (1 件 1 行)
- `mart_gbizinfo_commendation` — 表彰実績 (1 件 1 行)
- `mart_gbizinfo_certification` — 届出・認定実績 (1 件 1 行)
- `mart_gbizinfo_patent` — 特許・意匠・商標の登録実績 (1 件 1 行)

### 財務情報の期の扱い

財務情報は 1 法人あたり直近 5 期分を回次 (`period_number`) 0〜4 で持つ (0 が最新)。
ただし gBizINFO が返す事業年度の表記は最新期のぶんしか無く、どの回次の行にも同じ文字列
(例「第20期（自 2025年４月１日 至 2026年３月31日）」) が入る。

そのため `stg_gbizinfo_finance` でこの表記から最新期の期末日 `latest_period_end` を取り出し
(和暦表記も西暦へ変換する)、そこから回次の分だけ年をさかのぼった `period_end_estimated` を
付けている。後者は推定値で、決算期を変更した法人ではずれる。回次の無い期の行は作らない。

表記のゆれは「至 ...」と「...から ...まで」の 2 通りと、和暦の「元年」がある。いずれも
解釈しており、収録 24,294 行すべてで期末日が取れている (2026-08 時点)。

## 取得方式

gBizINFO のデータダウンロード (DownloadTop) から全件 CSV を取得する。各ファイルは
日次更新されるため、更新頻度に応じて 2 モードに分けて鮮度を上げている。

- full (月次): 基本情報・特許を含む全 8 種別を取得して全モデルを再ビルドする
  (基本情報 Kihonjoho 約 1.7GB・特許 Tokkyojoho 約 1.2GB は重いが変化が緩やかなため月次)。
  ワークフロー: `.github/workflows/sync.yml`
- activity (日次): 活動 6 種別 (補助金・調達・財務・職場・表彰・届出認定) のみ取得し、
  `dbt build --exclude raw_gbizinfo_basic raw_gbizinfo_patent` で基本情報・特許層を
  据え置いたまま活動データと mart を再ビルドする。
  ワークフロー: `.github/workflows/sync-activity.yml`

モードは環境変数 `GBIZINFO_SYNC_MODE` (`full` 既定 / `activity`) で切り替える。
activity モードでも基本情報・特許テーブルが揃っていなければ full にフォールバックする。

法人の名称・住所は国税庁法人番号 (dataset-houjin-bangou) と重複するため、本データセットは
corporate_number で結合できる形を保ち、物理的な結合はしない (利用側で結合する)。

## セットアップと実行

```bash
uv sync
echo "QUERIA_TOKEN=<Queria の API トークン>" > .env
echo "GBIZINFO_API_TOKEN=<gBizINFO アクセストークン>" >> .env

scripts/build.sh                    # ビルドして Queria に公開する
```

`GBIZINFO_API_TOKEN` は gBizINFO の API 利用申請で発行されるアクセストークン
(REST API と データダウンロードで共通)。

## ライセンス

出典：gBizINFO（経済産業省）。gBizINFO 利用規約に基づき出典を明記して再配布する。
