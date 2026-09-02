#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
ensure_target_user

pacman -S --needed --noconfirm zsh git

if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    run_as_user git clone --depth=1 \
        https://github.com/ohmyzsh/ohmyzsh.git \
        "$USER_HOME/.oh-my-zsh"
fi

if [ ! -d "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    run_as_user git clone --depth=1 \
        https://github.com/romkatv/powerlevel10k.git \
        "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fi

if [ ! -d "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    run_as_user git clone --depth=1 \
        https://github.com/zsh-users/zsh-autosuggestions \
        "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi

if [ "$(getent passwd "$USERNAME" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
    chsh -s /usr/bin/zsh "$USERNAME"
fi
