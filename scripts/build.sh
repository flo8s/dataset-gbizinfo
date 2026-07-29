#!/usr/bin/env bash
set -euo pipefail
# activity モードは前回 full ビルドの raw_gbizinfo_basic を据え置いて参照するので、
# 公開済みカタログの取り込みが前提。queria sync は pull から始まるので、ここで pull しない
exec "$(dirname "$0")/../shared/scripts/build-dataset.sh"
