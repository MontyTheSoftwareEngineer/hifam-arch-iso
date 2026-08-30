#!/bin/sh

echo "Set up symlinks for HiFam configs"

# Determine the config directory
if [ -d "$HOME/hifam-config" ]; then
    CONFIG_DIR="$HOME/hifam-config"
elif [ -d "$HOME/OmarchyDotFiles" ]; then
    CONFIG_DIR="$HOME/OmarchyDotFiles"
else
    echo "Error: Config directory not found!"
    echo "Looked for: $HOME/hifam-config or $HOME/OmarchyDotFiles"
    exit 1
fi

echo "Using config directory: $CONFIG_DIR"

echo "Nvim..."
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
fi
ln -sf "$CONFIG_DIR/nvim" "$HOME/.config/nvim"

echo "Kitty..."
if [ -d "$HOME/.config/kitty" ] && [ ! -L "$HOME/.config/kitty" ]; then
    mv "$HOME/.config/kitty" "$HOME/.config/kitty.bak"
fi
ln -sf "$CONFIG_DIR/kitty" "$HOME/.config/kitty"

echo "Tmux..."
mkdir -p "$HOME/.config/tmux"
cp "$CONFIG_DIR/tmux.conf" "$HOME/.config/tmux/"

echo "Hypr..."
if [ -d "$HOME/.config/hypr" ] && [ ! -L "$HOME/.config/hypr" ]; then
    mv "$HOME/.config/hypr" "$HOME/.config/hypr.bak"
fi
if [ -d "$CONFIG_DIR/hypr" ]; then
    ln -sf "$CONFIG_DIR/hypr" "$HOME/.config/hypr"
fi

# Waybar if it exists
if [ -d "$CONFIG_DIR/waybar" ]; then
    echo "Waybar..."
    if [ -d "$HOME/.config/waybar" ] && [ ! -L "$HOME/.config/waybar" ]; then
        mv "$HOME/.config/waybar" "$HOME/.config/waybar.bak"
    fi
    ln -sf "$CONFIG_DIR/waybar" "$HOME/.config/waybar"
fi

echo "Symlinks complete!"
