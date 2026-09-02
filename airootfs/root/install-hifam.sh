#!/bin/bash
# HiFam Arch Installer entrypoint

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_START_FILE="/tmp/hifam-install-start-epoch"
WIFI_STAGING_FILE="/tmp/hifam-install-wifi.env"

echo "╔════════════════════════════════════════╗"
echo "║   HiFam Arch Linux Installation        ║"
echo "╚════════════════════════════════════════╝"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

date +%s > "$INSTALL_START_FILE"
rm -f "$WIFI_STAGING_FILE"

echo "Installation plan:"
echo "1. Optionally connect Wi-Fi for networked post-install steps"
echo "2. Run the Arch installation flow"
echo "3. Copy HiFam configs into the new system"
echo "4. Run the automated post-install setup inside the new system"
echo ""

read -rp "Proceed with installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

if [ -x "$SCRIPT_DIR/wifi-connect.sh" ]; then
    echo ""
    if curl -fsI --connect-timeout 5 https://archlinux.org >/dev/null 2>&1; then
        echo "Network connectivity detected."
        read -rp "Reconfigure Wi-Fi before installation? [y/N]: " WIFI_REPLY
    else
        echo "No internet connectivity detected."
        echo "The installer and post-install scripts may need network access."
        read -rp "Connect to Wi-Fi before installation? [Y/n]: " WIFI_REPLY
    fi

    if [[ -z "${WIFI_REPLY:-}" || "$WIFI_REPLY" =~ ^[Yy]$ ]]; then
        if ! "$SCRIPT_DIR/wifi-connect.sh"; then
            echo ""
            echo "Wi-Fi setup did not complete."
            echo "Installation may still continue,"
            echo "but networked steps may fail until connectivity is available."
        fi
    fi
fi

"$SCRIPT_DIR/arch-install.sh"
"$SCRIPT_DIR/post-install.sh"
