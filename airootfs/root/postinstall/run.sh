#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════╗"
echo "║   HiFam Chroot Post-Install Runner     ║"
echo "╚════════════════════════════════════════╝"

source "$SCRIPT_DIR/common.sh"
ensure_target_user

echo "Configuring user: $USERNAME ($USER_HOME)"

for script in "$SCRIPT_DIR"/[0-9][0-9]-*.sh; do
    script_name="$(basename "$script")"
    echo ""
    echo "=== $script_name ==="
    "$script"
done

chown -R "$USERNAME:$USERNAME" "$USER_HOME"
chown -R "$USERNAME:$USERNAME" /usr/share/hifam
chmod -R u+rwX,go+rX /usr/share/hifam

echo ""
echo "HiFam post-install tasks completed."
