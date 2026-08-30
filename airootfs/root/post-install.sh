#!/bin/bash
# Post-installation script for HiFam Arch
# This script will be run in the chroot environment after installation

# Don't exit on error - continue even if some steps fail
echo "=== HiFam Arch Post-Installation Script ==="
echo ""

# Get the username from the first non-root user in the system
USERNAME=$(getent passwd {1000..60000} | head -n1 | cut -d: -f1)
USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)

if [ -z "$USERNAME" ] || [ -z "$USER_HOME" ]; then
    echo "Warning: Could not determine username from existing users."
    echo "Checking for user in user_credentials.json..."
    
    # Try to get username from the credentials file
    if [ -f "/root/hifam-config/user_credentials.json" ]; then
        USERNAME=$(grep -o '"!users" *: *\[{[^}]*"username" *: *"[^"]*"' /root/hifam-config/user_credentials.json | grep -o '"username" *: *"[^"]*"' | cut -d'"' -f4)
    fi
    
    if [ -z "$USERNAME" ]; then
        echo "Creating default user 'hifam'..."
        USERNAME="hifam"
        USER_HOME="/home/$USERNAME"
        useradd -m -G wheel -s /bin/zsh "$USERNAME" || echo "User creation failed, continuing anyway"
    else
        USER_HOME="/home/$USERNAME"
    fi
fi

echo "Installing for user: $USERNAME ($USER_HOME)"
echo ""

# Create config directory in user home
CONFIG_SOURCE="/root/hifam-config"
CONFIG_DEST="$USER_HOME/hifam-config"

if [ -d "$CONFIG_SOURCE" ]; then
    echo "Copying configuration files to $CONFIG_DEST..."
    mkdir -p "$CONFIG_DEST"
    cp -r "$CONFIG_SOURCE"/* "$CONFIG_DEST/" || echo "Some config files failed to copy"
    chown -R "$USERNAME:$USERNAME" "$CONFIG_DEST" 2>/dev/null || true
else
    echo "ERROR: Configuration source not found at $CONFIG_SOURCE"
    echo "This means the configs weren't copied during installation."
    echo "You'll need to manually copy them."
    exit 1
fi

# Setup keyd configuration
echo ""
echo "Setting up keyd..."
if [ -d "$CONFIG_DEST/keyd" ]; then
    mkdir -p /etc/keyd
    cp "$CONFIG_DEST/keyd/default.conf" /etc/keyd/ 2>/dev/null && echo "  ✓ keyd config copied" || echo "  ✗ keyd config copy failed"
    systemctl enable keyd 2>/dev/null && echo "  ✓ keyd service enabled" || echo "  ✗ keyd service enable failed (may not be installed)"
fi

# Setup Plymouth theme
echo ""
echo "Setting up Plymouth boot splash..."
if [ -d "/usr/share/plymouth/themes/hifam" ]; then
    plymouth-set-default-theme hifam 2>/dev/null && echo "  ✓ Plymouth theme set to hifam" || echo "  ✗ Plymouth theme setup failed"
    # Rebuild initramfs to include Plymouth theme
    mkinitcpio -P 2>/dev/null && echo "  ✓ Initramfs rebuilt" || echo "  ✗ Initramfs rebuild failed"
else
    echo "  ⚠ Plymouth HiFam theme not found at /usr/share/plymouth/themes/hifam"
    echo "    (Plymouth will use default theme)"
fi

# Create .config directory structure
echo ""
echo "Creating .config directories..."
mkdir -p "$USER_HOME/.config"/{nvim,kitty,hypr,tmux,waybar} 2>/dev/null
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config" 2>/dev/null

# Run the setup scripts
echo ""
echo "══════════════════════════════════════════════════════"
echo "Running installation scripts..."
echo "══════════════════════════════════════════════════════"

cd "$CONFIG_DEST" || exit 1

if [ -d "hifam-arch-scripts" ]; then
    # Install packages (run as root)
    if [ -f "hifam-arch-scripts/2-install-packages.sh" ]; then
        echo ""
        echo "Installing packages (this may take a while)..."
        bash "hifam-arch-scripts/2-install-packages.sh" || echo "⚠ Some packages failed to install"
    fi
    
    # Run other scripts as the target user
    for script in hifam-arch-scripts/*.sh; do
        if [ -f "$script" ] && [ "$script" != "hifam-arch-scripts/2-install-packages.sh" ]; then
            echo ""
            echo "Running $(basename "$script")..."
            su - "$USERNAME" -c "cd '$CONFIG_DEST' && bash '$script'" 2>&1 | tee "/var/log/$(basename "$script").log" || echo "⚠ $(basename "$script") had issues"
        fi
    done
else
    echo "⚠ hifam-arch-scripts directory not found, skipping script execution"
fi

# Create symlinks for dotfiles
echo ""
echo "══════════════════════════════════════════════════════"
echo "Setting up dotfiles..."
echo "══════════════════════════════════════════════════════"
cd "$USER_HOME" || exit 1

# Backup existing configs
for dir in nvim kitty hypr waybar; do
    if [ -d "$USER_HOME/.config/$dir" ] && [ ! -L "$USER_HOME/.config/$dir" ]; then
        echo "  Backing up existing $dir config..."
        mv "$USER_HOME/.config/$dir" "$USER_HOME/.config/${dir}.backup" 2>/dev/null || true
    fi
done

# Create symlinks
echo "Creating symlinks..."
[ -d "$CONFIG_DEST/nvim" ] && ln -sf "$CONFIG_DEST/nvim" "$USER_HOME/.config/nvim" && echo "  ✓ nvim"
[ -d "$CONFIG_DEST/kitty" ] && ln -sf "$CONFIG_DEST/kitty" "$USER_HOME/.config/kitty" && echo "  ✓ kitty"
[ -d "$CONFIG_DEST/hypr" ] && ln -sf "$CONFIG_DEST/hypr" "$USER_HOME/.config/hypr" && echo "  ✓ hypr"
[ -d "$CONFIG_DEST/waybar" ] && ln -sf "$CONFIG_DEST/waybar" "$USER_HOME/.config/waybar" && echo "  ✓ waybar"

# Copy tmux config
echo "Copying configs..."
[ -f "$CONFIG_DEST/tmux.conf" ] && cp "$CONFIG_DEST/tmux.conf" "$USER_HOME/.config/tmux/" && echo "  ✓ tmux.conf"

# Copy shell configs
[ -f "$CONFIG_DEST/zshrc" ] && cp "$CONFIG_DEST/zshrc" "$USER_HOME/.zshrc" && echo "  ✓ .zshrc"
[ -f "$CONFIG_DEST/p10k.zsh" ] && cp "$CONFIG_DEST/p10k.zsh" "$USER_HOME/.p10k.zsh" && echo "  ✓ .p10k.zsh"

# Fix ownership
echo ""
echo "Fixing file ownership..."
chown -R "$USERNAME:$USERNAME" "$USER_HOME" 2>/dev/null || echo "⚠ Failed to fix some ownership"

echo ""
echo "══════════════════════════════════════════════════════"
echo "✅ Post-installation complete!"
echo "══════════════════════════════════════════════════════"
echo ""
echo "Configuration summary:"
echo "  • User: $USERNAME"
echo "  • Config location: $CONFIG_DEST"
echo "  • Logs: /var/log/hifam-*.log"
echo ""
echo "Configured items:"
echo "  • Dotfiles (nvim, kitty, hypr, waybar)"
echo "  • Shell (zsh with p10k)"
echo "  • Tmux configuration"
echo "  • Keyd keyboard remapping"
if [ -d "/usr/share/plymouth/themes/hifam" ]; then
    echo "  • Plymouth boot splash (HiFam theme)"
fi
echo ""
echo "What to do next:"
echo "  1. Exit chroot (if in chroot): exit"
echo "  2. Unmount partitions: umount -R /mnt"
echo "  3. Reboot: reboot"
echo "  4. Set user password if needed: passwd $USERNAME"
echo ""
echo "After reboot:"
echo "  • Your dotfiles will be active"
echo "  • Plymouth splash will show HiFam logo"
echo "  • Keyd remapping will be active"
echo ""

exit 0
