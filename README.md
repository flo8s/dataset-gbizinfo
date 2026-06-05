# dataset-gbizinfo

経済産業省 gBizINFO の法人活動情報を取得し、DuckLake (Neon + R2) に公開するデータセット。
法人番号 (corporate_number) をキーに国税庁法人番号 (dataset-houjin-bangou) や
全国地方公共団体コード (dataset-lg-code) と結合できる。

## 収録データ

gBizINFO の「データダウンロード」から取得した 5 種別の全件データ:

- 基本情報 (資本金・従業員数・設立年・事業概要・業種)
- 補助金交付実績
- 国の調達 (受注) 実績
- 財務情報
- 職場情報 (女性活躍・両立支援の指標)

公開 mart:

- `mart_gbizinfo_company` — 法人 1 行の活動サマリ (基本属性 + 補助金/調達集計 + 最新財務 + 職場指標)
- `mart_gbizinfo_subsidy` — 補助金交付実績 (1 件 1 行)
- `mart_gbizinfo_procurement` — 調達 (受注) 実績 (1 件 1 行)

## 取得方式

当面は gBizINFO の一括ダウンロード (DownloadTop) から全件 CSV を取得する方式のみ。
初回も月次更新も全件を再取得する (全件で約 1.9GB)。

将来的には REST API (`updateInfo` + 法人番号別取得) による差分更新への最適化余地がある
(REST のレスポンス構造は一括 CSV と異なるため、別途マッパーの実装が必要)。

## セットアップと実行

```bash
uv sync
cp ../dataset-reinfolib/.env .env   # R2 / Neon の認証情報
echo "GBIZINFO_API_TOKEN=<gBizINFO アクセストークン>" >> .env

scripts/build.sh local              # dev_gbizinfo へビルド
scripts/build.sh default            # 本番 (gbizinfo) へビルド
```

`GBIZINFO_API_TOKEN` は gBizINFO の API 利用申請で発行されるアクセストークン
(REST API と データダウンロードで共通)。

## ライセンス

出典：gBizINFO（経済産業省）。gBizINFO 利用規約に基づき出典を明記して再配布する。
