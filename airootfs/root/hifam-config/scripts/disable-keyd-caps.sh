#!/usr/bin/env bash

set -euo pipefail

die() {
    echo "Error: $*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

require_cmd sudo
require_cmd systemctl

TARGET_CONFIG="/etc/keyd/default.conf"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
HYPR_INPUT="$REPO_ROOT/hypr/input.conf"
HYPR_PATTERN='^[[:space:]]*# kb_options = ctrl:nocaps$'
MOUSELESS_APP_ID="net.sonuscape.mouseless"
RESTART_MOUSELESS=0

start_mouseless() {
    if [[ "$RESTART_MOUSELESS" -eq 1 ]]; then
        nohup flatpak run "$MOUSELESS_APP_ID" >/dev/null 2>&1 &
    fi
}

[ -f "$HYPR_INPUT" ] || die "Missing Hyprland input config: $HYPR_INPUT"

mapfile -t mouseless_units < <(systemctl --user list-units --all --plain --no-legend 'app-flatpak-net.sonuscape.mouseless-*.scope' 2>/dev/null | awk '{print $1}')
if [[ "${#mouseless_units[@]}" -gt 0 ]]; then
    systemctl --user stop "${mouseless_units[@]}"
    RESTART_MOUSELESS=1
fi

if sudo test -f "$TARGET_CONFIG"; then
    latest_backup="$(sudo find /etc/keyd -maxdepth 1 -type f -name 'default.conf.bak.*' | sort | tail -n 1)"
    if [[ -n "${latest_backup:-}" ]]; then
        sudo cp "$latest_backup" "$TARGET_CONFIG"
        echo "Restored $TARGET_CONFIG from $latest_backup"
    else
        sudo rm -f "$TARGET_CONFIG"
        echo "Removed $TARGET_CONFIG"
    fi
fi

sudo systemctl disable --now keyd || true

if grep -q "$HYPR_PATTERN" "$HYPR_INPUT"; then
    sed -i "s|$HYPR_PATTERN|  kb_options = ctrl:nocaps|" "$HYPR_INPUT"
fi

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

start_mouseless

echo "keyd disabled"
