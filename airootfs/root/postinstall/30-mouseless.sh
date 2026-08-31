#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
ensure_target_user

pacman -S --needed --noconfirm flatpak

if ! getent group mouseless >/dev/null; then
    groupadd --system mouseless
fi

usermod -aG input,mouseless "$USERNAME"

install -d /etc/udev/rules.d /etc/modules-load.d
cat > /etc/udev/rules.d/99-mouseless-input.rules <<'EOF'
KERNEL=="uinput", GROUP="mouseless", MODE:="0660"
EOF
printf 'uinput\n' > /etc/modules-load.d/uinput.conf

flatpak remote-add --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install -y flathub org.gnome.Platform//50

flatpak remote-add --if-not-exists \
    sonuscape \
    https://dl.sonuscape.net/flatpak/sonuscape.flatpakrepo

flatpak install -y \
    sonuscape \
    net.sonuscape.mouseless

if [ -f "$CONFIG_DIR/mouseless/config.yaml" ]; then
    install -d "$USER_HOME/.var/app/net.sonuscape.mouseless/data/mouseless/configs"
    install -m 0644 \
        "$CONFIG_DIR/mouseless/config.yaml" \
        "$USER_HOME/.var/app/net.sonuscape.mouseless/data/mouseless/configs/config.yaml"
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.var/app/net.sonuscape.mouseless"
fi
