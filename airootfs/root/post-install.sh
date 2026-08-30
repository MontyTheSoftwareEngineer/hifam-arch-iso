#!/bin/bash
# Post-installation script for HiFam Arch
# This script will be run in the chroot environment after installation

set -e

echo "=== HiFam Arch Post-Installation Script ==="

# Get the username from the first non-root user in the system
USERNAME=$(getent passwd {1000..60000} | head -n1 | cut -d: -f1)
USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)

if [ -z "$USERNAME" ] || [ -z "$USER_HOME" ]; then
    echo "Error: Could not determine username. Creating default user 'hifam'..."
    USERNAME="hifam"
    USER_HOME="/home/$USERNAME"
    useradd -m -G wheel -s /bin/zsh "$USERNAME"
fi

echo "Installing for user: $USERNAME ($USER_HOME)"

# Create config directory in user home
CONFIG_SOURCE="/root/hifam-config"
CONFIG_DEST="$USER_HOME/hifam-config"

if [ -d "$CONFIG_SOURCE" ]; then
    echo "Copying configuration files to $CONFIG_DEST..."
    mkdir -p "$CONFIG_DEST"
    cp -r "$CONFIG_SOURCE"/* "$CONFIG_DEST/"
    chown -R "$USERNAME:$USERNAME" "$CONFIG_DEST"
else
    echo "Warning: Configuration source not found at $CONFIG_SOURCE"
    exit 1
fi

# Setup keyd configuration
echo "Setting up keyd..."
if [ -d "$CONFIG_DEST/keyd" ]; then
    mkdir -p /etc/keyd
    cp "$CONFIG_DEST/keyd/default.conf" /etc/keyd/ 2>/dev/null || true
    systemctl enable keyd 2>/dev/null || echo "keyd service not available yet"
fi

# Setup Plymouth theme
echo "Setting up Plymouth boot splash..."
if [ -d "/usr/share/plymouth/themes/hifam" ]; then
    plymouth-set-default-theme -R hifam 2>/dev/null || echo "Plymouth theme will be configured on first boot"
fi

# Create .config directory structure
echo "Creating .config directories..."
mkdir -p "$USER_HOME/.config"/{nvim,kitty,hypr,tmux}
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"

# Run the setup scripts as the user
echo "Running installation scripts..."

# Change to user context for script execution
cd "$CONFIG_DEST"

if [ -f "hifam-arch-scripts/2-install-packages.sh" ]; then
    echo "Installing packages..."
    # Run as root since it uses pacman
    bash "hifam-arch-scripts/2-install-packages.sh" 2>&1 | tee /var/log/hifam-packages.log || echo "Package installation had issues, check /var/log/hifam-packages.log"
fi

# Run other scripts as the target user
for script in hifam-arch-scripts/*.sh; do
    if [ -f "$script" ] && [ "$script" != "hifam-arch-scripts/2-install-packages.sh" ]; then
        echo "Running $(basename "$script")..."
        su - "$USERNAME" -c "cd '$CONFIG_DEST' && bash '$script'" 2>&1 | tee "/var/log/$(basename "$script").log" || echo "Warning: $script had issues"
    fi
done

# Create symlinks for dotfiles
echo "Setting up dotfiles..."
cd "$USER_HOME"

# Backup existing configs
for dir in nvim kitty hypr; do
    if [ -d "$USER_HOME/.config/$dir" ] && [ ! -L "$USER_HOME/.config/$dir" ]; then
        mv "$USER_HOME/.config/$dir" "$USER_HOME/.config/${dir}.backup" 2>/dev/null || true
    fi
done

# Create symlinks
[ -d "$CONFIG_DEST/nvim" ] && ln -sf "$CONFIG_DEST/nvim" "$USER_HOME/.config/nvim"
[ -d "$CONFIG_DEST/kitty" ] && ln -sf "$CONFIG_DEST/kitty" "$USER_HOME/.config/kitty"
[ -d "$CONFIG_DEST/hypr" ] && ln -sf "$CONFIG_DEST/hypr" "$USER_HOME/.config/hypr"

# Copy tmux config
[ -f "$CONFIG_DEST/tmux.conf" ] && cp "$CONFIG_DEST/tmux.conf" "$USER_HOME/.config/tmux/"

# Copy shell configs
[ -f "$CONFIG_DEST/zshrc" ] && cp "$CONFIG_DEST/zshrc" "$USER_HOME/.zshrc"
[ -f "$CONFIG_DEST/p10k.zsh" ] && cp "$CONFIG_DEST/p10k.zsh" "$USER_HOME/.p10k.zsh"

# Fix ownership
chown -R "$USERNAME:$USERNAME" "$USER_HOME"

echo "=== Post-installation complete! ==="
echo "Configuration files are in: $CONFIG_DEST"
echo "Logs are in: /var/log/hifam-*.log"
echo ""
echo "Next steps:"
echo "1. Set password for $USERNAME: passwd $USERNAME"
echo "2. Reboot into your new system"
echo "3. Check logs if anything didn't work as expected"

exit 0
