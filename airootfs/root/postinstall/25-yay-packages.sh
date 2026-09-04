#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
ensure_target_user

cleanup() {
    remove_temp_pacman_nopasswd
}

trap cleanup EXIT

install_temp_pacman_nopasswd

if ! command -v yay >/dev/null 2>&1; then
    run_as_user bash -lc '
        set -euo pipefail

        build_root="$HOME/.cache/hifam-build"
        repo_dir="$build_root/yay"

        rm -rf "$repo_dir"
        install -d "$build_root"
        git clone --depth=1 https://aur.archlinux.org/yay.git "$repo_dir"
        cd "$repo_dir"
        makepkg -si --noconfirm --needed
        rm -rf "$repo_dir"
    '
fi

run_as_user yay -S --needed --noconfirm \
    --answerclean None \
    --answerdiff None \
    --answeredit None \
    --removemake \
    google-chrome

pacman -S --needed --noconfirm ttf-material-symbols-variable
