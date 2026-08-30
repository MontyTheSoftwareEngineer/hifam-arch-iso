#!/usr/bin/env bash

set -euo pipefail

die() {
    echo "Error: $*" >&2
    exit 1
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SOURCE_CONFIG="$REPO_ROOT/keyd/default.conf"
TARGET_CONFIG="/etc/keyd/default.conf"
HYPR_INPUT="$REPO_ROOT/hypr/input.conf"
HYPR_PATTERN='^[[:space:]]*kb_options = ctrl:nocaps$'
HYPR_COMMENT='  # kb_options = ctrl:nocaps'
MOUSELESS_APP_ID="net.sonuscape.mouseless"
RESTART_MOUSELESS=0

start_mouseless() {
    if [[ "$RESTART_MOUSELESS" -eq 1 ]]; then
        nohup flatpak run "$MOUSELESS_APP_ID" >/dev/null 2>&1 &
    fi
}

require_cmd sudo
require_cmd keyd
require_cmd systemctl
require_cmd flatpak

[ -f "$SOURCE_CONFIG" ] || die "Missing source config: $SOURCE_CONFIG"
[ -f "$HYPR_INPUT" ] || die "Missing Hyprland input config: $HYPR_INPUT"

sudo install -d /etc/keyd

if sudo test -f "$TARGET_CONFIG"; then
    backup_path="${TARGET_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
    sudo cp "$TARGET_CONFIG" "$backup_path"
    echo "Backed up existing config to $backup_path"
fi

mapfile -t mouseless_units < <(systemctl --user list-units --all --plain --no-legend 'app-flatpak-net.sonuscape.mouseless-*.scope' 2>/dev/null | awk '{print $1}')
if [[ "${#mouseless_units[@]}" -gt 0 ]]; then
    systemctl --user stop "${mouseless_units[@]}"
    RESTART_MOUSELESS=1
fi

if grep -q "$HYPR_PATTERN" "$HYPR_INPUT"; then
    sed -i "s|$HYPR_PATTERN|$HYPR_COMMENT|" "$HYPR_INPUT"
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 || true
    fi
fi

sudo install -m 644 "$SOURCE_CONFIG" "$TARGET_CONFIG"
sudo keyd check "$TARGET_CONFIG"
sudo systemctl enable --now keyd
sudo keyd reload
start_mouseless

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

echo "Installed $TARGET_CONFIG"
