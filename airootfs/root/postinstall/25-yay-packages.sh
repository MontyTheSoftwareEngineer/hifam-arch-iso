#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
ensure_target_user

if ! command -v yay >/dev/null 2>&1; then
    echo "ERROR: yay must be installed before running $(basename "$0")."
    exit 1
fi

run_as_user yay -S --needed --noconfirm ttf-material-symbols-variable-git
