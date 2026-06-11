#!/usr/bin/env bash
set -euo pipefail
target="${1:-local}"
# activity モードは前回 full ビルドの raw_gbizinfo_basic を据え置いて参照するため、
# 公開済みカタログを取り込んでからビルドする (初回は未公開なので無視)。
uv run fdl pull "$target" || true
exec "$(dirname "$0")/../shared/scripts/build-dataset.sh" "$target"
