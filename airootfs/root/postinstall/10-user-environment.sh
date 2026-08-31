#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
ensure_target_user

mkdir -p "$USER_HOME/.config/tmux"

for config_name in nvim kitty hypr waybar mouseless quickshell; do
    if [ -d "$CONFIG_DIR/$config_name" ]; then
        backup_user_config_dir "$config_name"
        ln -sfn "$CONFIG_DIR/$config_name" "$USER_HOME/.config/$config_name"
    fi
done

if [ -f "$CONFIG_DIR/tmux/tmux.conf" ]; then
    install -m 0644 "$CONFIG_DIR/tmux/tmux.conf" "$USER_HOME/.config/tmux/tmux.conf"
fi

if [ -f "$CONFIG_DIR/zshrc" ]; then
    install -m 0644 "$CONFIG_DIR/zshrc" "$USER_HOME/.zshrc"
fi

if [ -f "$CONFIG_DIR/p10k.zsh" ]; then
    install -m 0644 "$CONFIG_DIR/p10k.zsh" "$USER_HOME/.p10k.zsh"
fi

if [ -f "$CONFIG_DIR/zsh_history" ]; then
    install -m 0644 "$CONFIG_DIR/zsh_history" "$USER_HOME/.zsh_history"
fi

if [ -d "$USER_HOME/.config" ]; then
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"
fi

for home_file in "$USER_HOME/.zshrc" "$USER_HOME/.p10k.zsh" "$USER_HOME/.zsh_history"; do
    if [ -f "$home_file" ]; then
        chown "$USERNAME:$USERNAME" "$home_file"
    fi
done
