#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
ensure_target_user

pacman -S --needed --noconfirm git meson ninja opencv

run_as_user bash -lc '
    set -euo pipefail
    rm -rf "$HOME/wl-kbptr"
    git clone --depth=1 --branch fix/opencv5 \
        https://github.com/DereckAn/wl-kbptr.git \
        "$HOME/wl-kbptr"
    cd "$HOME/wl-kbptr"
    meson setup build --buildtype=release -Dopencv=enabled
    meson compile -C build
'

install -m 0755 "$USER_HOME/wl-kbptr/build/wl-kbptr" /usr/bin/wl-kbptr
chown -R "$USERNAME:$USERNAME" "$USER_HOME/wl-kbptr"
