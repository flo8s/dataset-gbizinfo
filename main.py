"""gBizINFO 法人活動情報の取得 + dbt build + snapshot pipeline.

経済産業省 gBizINFO のデータダウンロード機能から情報種別ごとの全件 CSV を取得し、
そのパスを dbt の var として渡して raw→stg→mart を構築する。

取得方式は当面「一括ダウンロードのみ」。初回も月次も全件 CSV を再取得する
(全件で約 1.9GB。CI では負荷軽微)。REST API による差分更新は将来の最適化として
別途実装する余地を残している。

ダウンロード機構 (実証済み):
  1. GET /hojin/DownloadTop でセッション (JSESSIONID cookie) を確立する
  2. 同一セッションで POST /hojin/Download に種別・文字コード・トークンを送る
     (downtype を付けないとトークンエラーの HTML が返る)
  3. content-type が application/octet-stream なら CSV 本体が返る

snapshot は dbt build と同一プロセスで実行する必要がある
(dataset-shared/README.md の制約を参照)。
"""

from __future__ import annotations

import importlib.util
import logging
import os
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

import httpx
from dbt.cli.main import dbtRunner

SHARED_SCRIPTS = Path(__file__).resolve().parent / "shared" / "scripts"
_spec = importlib.util.spec_from_file_location(
    "snapshot_to_r2", SHARED_SCRIPTS / "snapshot-to-r2.py"
)
assert _spec and _spec.loader
snapshot_to_r2 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(snapshot_to_r2)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler())

BASE = "https://info.gbiz.go.jp/hojin"
DOWNLOAD_TOP = f"{BASE}/DownloadTop"
DOWNLOAD_URL = f"{BASE}/Download"
USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)


@dataclass(frozen=True)
class TypeSpec:
    """1 情報種別の取得・モデル化に必要な定義。"""

    key: str  # dbt var の suffix / 種別識別子 (例: basic)
    downfile: str  # DownloadTop の downfile パラメータ値


# 取得対象の 5 種別。dbt var 名は gbiz_<key>_csv。
TYPES: list[TypeSpec] = [
    TypeSpec("basic", "Kihonjoho"),
    TypeSpec("subsidy", "Hojokinjoho"),
    TypeSpec("procurement", "Chotatsujoho"),
    TypeSpec("finance", "Zaimujoho"),
    TypeSpec("workplace", "Shokubajoho"),
]


def _download_csv(client: httpx.Client, spec: TypeSpec, token: str, dest_dir: Path) -> Path:
    """1 種別の全件 CSV をストリーミングダウンロードしてローカルパスを返す。"""
    csv_path = dest_dir / f"{spec.downfile}.csv"
    logger.info("ダウンロード開始: %s (%s)", spec.key, spec.downfile)
    with client.stream(
        "POST",
        DOWNLOAD_URL,
        headers={"Referer": DOWNLOAD_TOP},
        data={
            "downfile": spec.downfile,
            "meta": "",
            "downenc": "UTF-8",
            "downtype": "csv",
            "apiToken": token,
        },
    ) as resp:
        resp.raise_for_status()
        content_type = resp.headers.get("content-type", "")
        if "text/html" in content_type:
            # トークン不正やセッション切れの場合 200 でも HTML が返る
            raise RuntimeError(
                f"{spec.key}: CSV ではなく HTML が返りました "
                f"(トークン/セッションを確認: content-type={content_type})"
            )
        with open(csv_path, "wb") as f:
            for chunk in resp.iter_bytes(1 << 20):
                f.write(chunk)
    size = csv_path.stat().st_size
    logger.info("ダウンロード完了: %s (%d bytes)", csv_path.name, size)
    return csv_path


def main() -> None:
    target = os.environ.get("DBT_TARGET", sys.argv[1] if len(sys.argv) > 1 else "default")
    token = os.environ["GBIZINFO_API_TOKEN"]

    # CSV は全件で約 1.9GB あるため一時ディレクトリへ。build 完了まで保持する
    # (raw モデルが read_csv で参照するため)。
    with tempfile.TemporaryDirectory(prefix="gbizinfo_") as tmp:
        dest = Path(tmp)
        dbt_vars_parts: list[str] = []
        with httpx.Client(
            headers={"User-Agent": USER_AGENT},
            follow_redirects=True,
            timeout=httpx.Timeout(60.0, read=1800.0),
        ) as client:
            # DownloadTop を GET して JSESSIONID cookie を確立してから取得する
            client.get(DOWNLOAD_TOP).raise_for_status()
            for spec in TYPES:
                csv_path = _download_csv(client, spec, token, dest)
                dbt_vars_parts.append(f"gbiz_{spec.key}_csv: '{csv_path}'")
        dbt_vars = "{" + ", ".join(dbt_vars_parts) + "}"

        # raw モデルが var('gbiz_<key>_csv') を参照するため、build だけでなく
        # docs generate にも同じ var を渡す (未指定だとコンパイルエラーになる)。
        dbt = dbtRunner()
        for cmd in (
            ["deps"],
            ["build", "--target", target, "--vars", dbt_vars],
            ["docs", "generate", "--target", target, "--vars", dbt_vars],
        ):
            result = dbt.invoke(cmd)
            if not result.success:
                raise SystemExit(f"dbt {' '.join(cmd)} failed")

    snapshot_to_r2.run(target)


if __name__ == "__main__":
    main()
