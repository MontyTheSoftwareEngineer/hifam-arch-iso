#!/bin/bash
# HiFam Arch Installer entrypoint

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════╗"
echo "║   HiFam Arch Linux Installation        ║"
echo "╚════════════════════════════════════════╝"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

echo "Installation plan:"
echo "1. Run the interactive Arch installation flow"
echo "2. Copy HiFam configs into the new system"
echo "3. Run the automated post-install setup inside the new system"
echo ""

read -rp "Proceed with installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

"$SCRIPT_DIR/arch-install.sh"
"$SCRIPT_DIR/post-install.sh"
