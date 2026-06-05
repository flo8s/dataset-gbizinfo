"""gBizINFO 法人活動情報の取得 + dbt build + snapshot pipeline.

経済産業省 gBizINFO のデータダウンロード機能から情報種別ごとの全件 CSV を取得し、
そのパスを dbt の var として渡して raw→stg→mart を構築する。

gBizINFO の各ファイル (特許を除く) は日次更新される。鮮度を上げるため、更新の
頻度に応じて取得対象を 2 モードに分ける:

  full (月次・既定):
    基本情報を含む全 5 種別を取得して全モデルをビルドする。
    基本情報 (Kihonjoho) は約 1.7GB と重いが変化が緩やかなため月次で十分。

  activity (日次): 環境変数 GBIZINFO_SYNC_MODE=activity で指定。
    補助金・調達・財務・職場の活動 4 種別 (計約 220MB) のみ取得し、
    `dbt build --exclude raw_gbizinfo_basic` で基本情報層を据え置いたまま
    活動データと mart を再ビルドする。基本情報は前回の full ビルドの
    raw_gbizinfo_basic テーブルをそのまま使う。

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

import duckdb
import httpx
from dbt.cli.main import dbtRunner

SHARED_SCRIPTS = Path(__file__).resolve().parent / "shared" / "scripts"
sys.path.insert(0, str(SHARED_SCRIPTS))
from queria_config import load_target  # noqa: E402

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


BASIC = TypeSpec("basic", "Kihonjoho")
# 日次更新する活動データ。dbt var 名は gbiz_<key>_csv。
ACTIVITY_TYPES: list[TypeSpec] = [
    TypeSpec("subsidy", "Hojokinjoho"),
    TypeSpec("procurement", "Chotatsujoho"),
    TypeSpec("finance", "Zaimujoho"),
    TypeSpec("workplace", "Shokubajoho"),
]
ALL_TYPES: list[TypeSpec] = [BASIC, *ACTIVITY_TYPES]

# activity モードで据え置く (再ビルドしない) 基本情報の raw モデル。
BASIC_RAW_MODEL = "raw_gbizinfo_basic"


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


def _raw_basic_exists(target_name: str) -> bool:
    """raw_gbizinfo_basic テーブルが DuckLake に存在するか確認する。

    activity モードは基本情報層を据え置くため、初回 (full 未実行) は成立しない。
    その場合は full にフォールバックさせる。
    """
    target = load_target(target_name)
    conn = duckdb.connect(":memory:")
    try:
        conn.execute("INSTALL ducklake; LOAD ducklake;")
        conn.execute("INSTALL postgres; LOAD postgres;")
        conn.execute("INSTALL httpfs; LOAD httpfs;")
        conn.execute(
            "CREATE SECRET r2 (TYPE r2, KEY_ID ?, SECRET ?, ACCOUNT_ID ?)",
            [target.s3_access_key_id, target.s3_secret_access_key, target.cf_account_id],
        )
        conn.execute(
            f"ATTACH '{target.ducklake_uri}' AS \"{target.dataset}\" "
            f"(DATA_PATH '{target.data_path}', META_SCHEMA '{target.meta_schema}')"
        )
        rows = conn.execute(
            "SELECT 1 FROM information_schema.tables "
            "WHERE table_catalog = ? AND table_name = ?",
            [target.dataset, BASIC_RAW_MODEL],
        ).fetchall()
        return bool(rows)
    finally:
        conn.close()


def main() -> None:
    target = os.environ.get("DBT_TARGET", sys.argv[1] if len(sys.argv) > 1 else "default")
    mode = os.environ.get("GBIZINFO_SYNC_MODE", "full").lower()
    token = os.environ["GBIZINFO_API_TOKEN"]

    if mode == "activity" and not _raw_basic_exists(target):
        logger.warning(
            "activity モードだが %s が存在しないため full にフォールバックします",
            BASIC_RAW_MODEL,
        )
        mode = "full"

    types = ACTIVITY_TYPES if mode == "activity" else ALL_TYPES
    logger.info("mode=%s: %d 種別を取得", mode, len(types))

    # CSV は一時ディレクトリへ。build 完了まで保持する (raw モデルが参照するため)。
    with tempfile.TemporaryDirectory(prefix="gbizinfo_") as tmp:
        dest = Path(tmp)
        downloaded: dict[str, Path] = {}
        with httpx.Client(
            headers={"User-Agent": USER_AGENT},
            follow_redirects=True,
            timeout=httpx.Timeout(60.0, read=1800.0),
        ) as client:
            # DownloadTop を GET して JSESSIONID cookie を確立してから取得する
            client.get(DOWNLOAD_TOP).raise_for_status()
            for spec in types:
                downloaded[spec.key] = _download_csv(client, spec, token, dest)

        # raw モデルは var('gbiz_<key>_csv') を参照するため、全 5 種別の var を
        # 定義する (activity モードで未取得の基本情報はダミーパス。raw_gbizinfo_basic
        # を --exclude するため実行時には参照されない)。
        unused = dest / "__unused__.csv"
        dbt_vars_parts = [
            f"gbiz_{spec.key}_csv: '{downloaded.get(spec.key, unused)}'"
            for spec in ALL_TYPES
        ]
        dbt_vars = "{" + ", ".join(dbt_vars_parts) + "}"

        build_cmd = ["build", "--target", target, "--vars", dbt_vars]
        if mode == "activity":
            build_cmd += ["--exclude", BASIC_RAW_MODEL]

        dbt = dbtRunner()
        for cmd in (
            ["deps"],
            build_cmd,
            ["docs", "generate", "--target", target, "--vars", dbt_vars],
        ):
            result = dbt.invoke(cmd)
            if not result.success:
                raise SystemExit(f"dbt {' '.join(cmd)} failed")

    snapshot_to_r2.run(target)


if __name__ == "__main__":
    main()
