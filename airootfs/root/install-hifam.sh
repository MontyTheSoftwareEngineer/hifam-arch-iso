#!/bin/bash
# HiFam Arch Installer Wrapper
# This script runs archinstall with your custom configuration
# and copies your configs to /usr/share/hifam for manual setup later

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$SCRIPT_DIR/hifam-config"

echo "╔════════════════════════════════════════╗"
echo "║   HiFam Arch Linux Installation        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

# Check for config files
if [ ! -f "$CONFIG_DIR/user_configuration.json" ]; then
    echo "Warning: user_configuration.json not found!"
    echo "Expected at: $CONFIG_DIR/user_configuration.json"
    echo ""
    read -p "Continue with manual archinstall configuration? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    USE_CONFIG=false
else
    USE_CONFIG=true
fi

# Show what will be done
echo "Installation plan:"
echo "1. Run archinstall with your configuration"
echo "2. Copy HiFam configs to /usr/share/hifam in the new system"
echo "3. You can manually run setup scripts after booting"
echo ""
read -p "Proceed with installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Run archinstall
echo ""
echo "=== Starting archinstall ==="
if [ "$USE_CONFIG" = true ]; then
    archinstall --config "$CONFIG_DIR/user_configuration.json" --creds "$CONFIG_DIR/user_credentials.json"
else
    archinstall
fi

INSTALL_EXIT=$?
echo ""
echo "archinstall exited with code: $INSTALL_EXIT"
sleep 2

# Find the mount point (usually /mnt)
MOUNT_POINT="/mnt"
if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo "Looking for installation mount point..."
    for mp in /mnt /install /target; do
        if [ -d "$mp/etc" ]; then
            MOUNT_POINT="$mp"
            echo "Found at: $mp"
            break
        fi
    done
fi

if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "WARNING: Could not find mounted installation at /mnt!"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "archinstall may have unmounted the system."
    lsblk -f
    echo ""
    read -p "Enter your root partition (e.g., /dev/sda2) or 'skip': " ROOT_PART
    
    if [ "$ROOT_PART" != "skip" ] && [ -b "$ROOT_PART" ]; then
        echo "Mounting $ROOT_PART to /mnt..."
        mount "$ROOT_PART" /mnt || { echo "Mount failed!"; exit 1; }
        
        read -p "Enter boot/ESP partition (e.g., /dev/sda1) or 'skip': " BOOT_PART
        if [ "$BOOT_PART" != "skip" ] && [ -b "$BOOT_PART" ]; then
            mkdir -p /mnt/boot
            mount "$BOOT_PART" /mnt/boot
        fi
        
        MOUNT_POINT="/mnt"
    else
        echo ""
        echo "Skipping config copy. To copy later:"
        echo "  1. Boot back to live USB"
        echo "  2. Mount your partitions to /mnt"
        echo "  3. mkdir -p /mnt/usr/share/hifam"
        echo "  4. cp -r /root/hifam-config/* /mnt/usr/share/hifam/"
        exit 0
    fi
fi

echo ""
echo "=== Installation found at: $MOUNT_POINT ==="

# Copy HiFam configs to /usr/share/hifam in the installed system
echo "Copying HiFam configuration to /usr/share/hifam..."
mkdir -p "$MOUNT_POINT/usr/share/hifam"
cp -rv "$CONFIG_DIR"/* "$MOUNT_POINT/usr/share/hifam/" || echo "Some files failed to copy"

# Copy Plymouth theme files if they exist
if [ -d "/usr/share/plymouth/themes/hifam" ]; then
    echo "Copying Plymouth theme..."
    mkdir -p "$MOUNT_POINT/usr/share/plymouth/themes/hifam"
    cp -r /usr/share/plymouth/themes/hifam/* "$MOUNT_POINT/usr/share/plymouth/themes/hifam/" || true
    
    # Activate Plymouth theme in the installed system
    echo "Activating Plymouth theme..."
    arch-chroot "$MOUNT_POINT" plymouth-set-default-theme hifam 2>&1 | grep -v "^$" || echo "  (Plymouth theme set)"
    
    echo "Rebuilding initramfs..."
    arch-chroot "$MOUNT_POINT" mkinitcpio -P 2>&1 | tail -5 || echo "  (Initramfs rebuild complete)"
    
    echo "✓ Plymouth theme activated!"
fi

# Create a simple README for the user
cat > "$MOUNT_POINT/usr/share/hifam/README.txt" << 'EOFREADME'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║  HiFam Arch Configuration Files                                  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Your HiFam dotfiles and configuration scripts are here!

LOCATION: /usr/share/hifam/

CONTENTS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• hifam-arch-scripts/  - Post-installation scripts
• nvim/                - Neovim configuration
• kitty/               - Kitty terminal config
• hypr/                - Hyprland configuration
• keyd/                - Keyboard remapping
• tmux.conf            - Tmux configuration
• zshrc                - Zsh shell config
• p10k.zsh             - Powerlevel10k theme
• user_configuration.json - Archinstall config reference

MANUAL SETUP:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Copy configs to your home:
   cp -r /usr/share/hifam ~/hifam-config

2. Run individual setup scripts:
   cd ~/hifam-config/hifam-arch-scripts
   ./2-install-packages.sh  (install packages)
   ./6-setup-symlinks.sh    (create dotfile symlinks)
   ./8-zsh-setup.sh         (setup zsh)
   etc...

3. Or manually create symlinks:
   ln -sf /usr/share/hifam/nvim ~/.config/nvim
   ln -sf /usr/share/hifam/kitty ~/.config/kitty
   ln -sf /usr/share/hifam/hypr ~/.config/hypr
   cp /usr/share/hifam/zshrc ~/.zshrc
   cp /usr/share/hifam/p10k.zsh ~/.p10k.zsh
   cp /usr/share/hifam/tmux.conf ~/.config/tmux/

4. Setup keyd (keyboard remapping):
   sudo cp /usr/share/hifam/keyd/default.conf /etc/keyd/
   sudo systemctl enable keyd
   sudo systemctl start keyd

5. Setup Plymouth (boot splash):
   sudo plymouth-set-default-theme hifam
   sudo mkinitcpio -P

QUICK START:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Copy everything to your home
cp -r /usr/share/hifam ~/hifam-config

# Create symlinks for main configs
mkdir -p ~/.config
ln -sf ~/hifam-config/nvim ~/.config/nvim
ln -sf ~/hifam-config/kitty ~/.config/kitty
ln -sf ~/hifam-config/hypr ~/.config/hypr

# Copy shell configs
cp ~/hifam-config/zshrc ~/.zshrc
cp ~/hifam-config/p10k.zsh ~/.p10k.zsh

# Setup keyd
sudo cp ~/hifam-config/keyd/default.conf /etc/keyd/
sudo systemctl enable --now keyd

# Setup Plymouth
sudo plymouth-set-default-theme hifam
sudo mkinitcpio -P

Done! Logout and login to see changes.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For more info: https://github.com/MontyTheSoftwareEngineer/hifam-arch
EOFREADME

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ Installation Complete!             ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Your configs are installed at: /usr/share/hifam"
echo ""
echo "Next steps:"
echo "  1. umount -R $MOUNT_POINT"
echo "  2. reboot"
echo ""
echo "After booting into your new system:"
echo "  • Your configs are in /usr/share/hifam"
echo "  • Read /usr/share/hifam/README.txt for setup instructions"
echo "  • Run scripts manually or copy configs as needed"
echo ""

exit 0
