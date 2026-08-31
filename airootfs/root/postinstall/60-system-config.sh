#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ -f "$CONFIG_DIR/keyd/default.conf" ]; then
    install -d /etc/keyd
    install -m 0644 "$CONFIG_DIR/keyd/default.conf" /etc/keyd/default.conf
    if [ -f /usr/lib/systemd/system/keyd.service ]; then
        systemctl enable keyd
    fi
fi

if [ -f /etc/default/grub ]; then
    if grep -q '^GRUB_DISTRIBUTOR=' /etc/default/grub; then
        sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="HiFam Arch"/' /etc/default/grub
    else
        printf '\nGRUB_DISTRIBUTOR="HiFam Arch"\n' >> /etc/default/grub
    fi

    if command -v grub-mkconfig >/dev/null 2>&1; then
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi

if [ -d /usr/share/plymouth/themes/hifam ] && command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme hifam
    mkinitcpio -P
fi
