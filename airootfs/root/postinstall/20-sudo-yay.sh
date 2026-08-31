#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
ensure_target_user

pacman -S --needed --noconfirm sudo base-devel git

printf '%s ALL=(ALL:ALL) ALL\n' "$USERNAME" > "/etc/sudoers.d/$USERNAME"
chmod 0440 "/etc/sudoers.d/$USERNAME"
visudo -cf "/etc/sudoers.d/$USERNAME"

if command -v yay >/dev/null 2>&1; then
    echo "yay is already installed."
    exit 0
fi

run_as_user bash -lc '
    set -euo pipefail
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -sf --noconfirm
'

pacman -U --noconfirm /tmp/yay/yay-*.pkg.tar.*
rm -rf /tmp/yay
