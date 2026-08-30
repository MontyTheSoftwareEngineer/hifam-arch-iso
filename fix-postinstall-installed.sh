#!/bin/bash
# Fix Post-Installation from Already-Installed System
# Run this from your installed Arch system if post-install didn't run

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  HiFam Arch - Fix Post-Installation (From Installed OS)   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in the installed system (not live environment)
if [ -d "/run/archiso" ]; then
    echo "ERROR: You're in the live environment!"
    echo "Boot into your installed system and run this script there."
    echo ""
    echo "Or use: ./run-postinstall-from-live.sh instead"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Trying with sudo..."
    exec sudo "$0" "$@"
fi

# Determine user
if [ -n "$SUDO_USER" ]; then
    USERNAME="$SUDO_USER"
else
    USERNAME=$(logname 2>/dev/null || echo "$USER")
fi

USER_HOME=$(eval echo "~$USERNAME")

echo "Setting up for user: $USERNAME ($USER_HOME)"
echo ""

# Check if configs exist in /root
if [ ! -d "/root/hifam-config" ]; then
    echo "HiFam configs not found in /root/hifam-config"
    echo ""
    echo "Do you have the configs somewhere else?"
    read -p "Enter path to hifam-config directory (or 'n' to exit): " CONFIG_PATH
    
    if [ "$CONFIG_PATH" = "n" ] || [ ! -d "$CONFIG_PATH" ]; then
        echo ""
        echo "You'll need to copy configs manually. Try:"
        echo "  1. Boot back to live USB"
        echo "  2. Mount your installation"
        echo "  3. Copy /root/hifam-config to /mnt/root/hifam-config"
        echo "  4. Run arch-chroot /mnt /root/post-install.sh"
        exit 1
    else
        mkdir -p /root/hifam-config
        cp -r "$CONFIG_PATH"/* /root/hifam-config/
    fi
fi

CONFIG_SOURCE="/root/hifam-config"
CONFIG_DEST="$USER_HOME/hifam-config"

echo "Copying configuration files to $CONFIG_DEST..."
mkdir -p "$CONFIG_DEST"
cp -r "$CONFIG_SOURCE"/* "$CONFIG_DEST/"
chown -R "$USERNAME:$USERNAME" "$CONFIG_DEST"

# Setup keyd
echo "Setting up keyd..."
if [ -d "$CONFIG_DEST/keyd" ]; then
    mkdir -p /etc/keyd
    cp "$CONFIG_DEST/keyd/default.conf" /etc/keyd/ 2>/dev/null || true
    systemctl enable keyd 2>/dev/null || true
    systemctl start keyd 2>/dev/null || echo "keyd will start on next boot"
fi

# Setup Plymouth theme
echo "Setting up Plymouth boot splash..."
if [ -d "/usr/share/plymouth/themes/hifam" ]; then
    plymouth-set-default-theme -R hifam 2>/dev/null || echo "Plymouth configured (takes effect on reboot)"
else
    echo "Warning: Plymouth HiFam theme not found. Installing..."
    # Create Plymouth theme if it doesn't exist
    mkdir -p /usr/share/plymouth/themes/hifam
    if [ -f "$CONFIG_DEST/../images/hifam-flag.png" ]; then
        cp "$CONFIG_DEST/../images/hifam-flag.png" /usr/share/plymouth/themes/hifam/logo.png
    fi
fi

# Create .config directories
echo "Creating .config directories..."
mkdir -p "$USER_HOME/.config"/{nvim,kitty,hypr,tmux}
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"

# Run installation scripts
echo ""
echo "Running installation scripts..."
cd "$CONFIG_DEST"

if [ -d "hifam-arch-scripts" ]; then
    # Install packages
    if [ -f "hifam-arch-scripts/2-install-packages.sh" ]; then
        echo "Installing packages..."
        bash "hifam-arch-scripts/2-install-packages.sh" 2>&1 | tee /var/log/hifam-packages.log || echo "Some packages failed, check log"
    fi
    
    # Run other scripts as the user
    for script in hifam-arch-scripts/*.sh; do
        if [ -f "$script" ] && [ "$script" != "hifam-arch-scripts/2-install-packages.sh" ]; then
            echo "Running $(basename "$script")..."
            su - "$USERNAME" -c "cd '$CONFIG_DEST' && bash '$script'" 2>&1 | tee "/var/log/$(basename "$script").log" || echo "Warning: $script had issues"
        fi
    done
fi

# Setup dotfiles
echo ""
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

# Copy other configs
[ -f "$CONFIG_DEST/tmux.conf" ] && cp "$CONFIG_DEST/tmux.conf" "$USER_HOME/.config/tmux/"
[ -f "$CONFIG_DEST/zshrc" ] && cp "$CONFIG_DEST/zshrc" "$USER_HOME/.zshrc"
[ -f "$CONFIG_DEST/p10k.zsh" ] && cp "$CONFIG_DEST/p10k.zsh" "$USER_HOME/.p10k.zsh"

# Fix ownership
chown -R "$USERNAME:$USERNAME" "$USER_HOME"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Post-Installation Complete!                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration applied for: $USERNAME"
echo "Configs location: $CONFIG_DEST"
echo "Logs: /var/log/hifam-*.log"
echo ""
echo "Changes take effect after:"
echo "  • Logout and login again (for shell and dotfiles)"
echo "  • Reboot (for Plymouth splash and keyd)"
echo ""
echo "Check dotfiles:"
echo "  ls -la ~/.config/nvim"
echo "  ls -la ~/.config/kitty"
echo "  ls -la ~/.config/hypr"
echo ""

exit 0
