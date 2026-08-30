#!/bin/bash
# Copy HiFam configs to installed system
# Run this from live USB AFTER archinstall finishes

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  HiFam Config Copy - Post Installation                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

CONFIG_SOURCE="/root/hifam-config"

# Check if configs exist
if [ ! -d "$CONFIG_SOURCE" ]; then
    echo "ERROR: HiFam configs not found at $CONFIG_SOURCE"
    echo "Make sure you're running from the live USB environment"
    exit 1
fi

# Check if /mnt is mounted
MOUNT_POINT="/mnt"
if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo "No system found at /mnt. Checking for installation..."
    lsblk -f
    echo ""
    read -p "Enter your root partition (e.g., /dev/sda2): " ROOT_PART
    
    if [ ! -b "$ROOT_PART" ]; then
        echo "ERROR: $ROOT_PART is not a valid block device"
        exit 1
    fi
    
    echo "Mounting $ROOT_PART to /mnt..."
    mount "$ROOT_PART" /mnt || { echo "Mount failed!"; exit 1; }
    
    # Ask about boot partition
    read -p "Do you have a separate boot/ESP partition? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter boot/ESP partition (e.g., /dev/sda1): " BOOT_PART
        if [ -b "$BOOT_PART" ]; then
            echo "Mounting $BOOT_PART to /mnt/boot..."
            mkdir -p /mnt/boot
            mount "$BOOT_PART" /mnt/boot || echo "Boot mount failed, continuing anyway"
        fi
    fi
fi

# Verify it's a valid installation
if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo "ERROR: Still no valid system at $MOUNT_POINT"
    exit 1
fi

echo ""
echo "✓ Found installation at: $MOUNT_POINT"
echo ""

# Copy configs to /usr/share/hifam
echo "Copying HiFam configs to /usr/share/hifam..."
mkdir -p "$MOUNT_POINT/usr/share/hifam"
cp -rv "$CONFIG_SOURCE"/* "$MOUNT_POINT/usr/share/hifam/" 2>&1 | grep -E "^'|copying|created"

# Copy Plymouth theme if it exists
if [ -d "/usr/share/plymouth/themes/hifam" ]; then
    echo ""
    echo "Copying Plymouth theme..."
    mkdir -p "$MOUNT_POINT/usr/share/plymouth/themes/hifam"
    cp -rv /usr/share/plymouth/themes/hifam/* "$MOUNT_POINT/usr/share/plymouth/themes/hifam/" 2>&1 | grep -E "^'|copying"
fi

# Create README
cat > "$MOUNT_POINT/usr/share/hifam/README.txt" << 'EOFREADME'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║  HiFam Arch Configuration Files                                  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Your HiFam dotfiles and configuration scripts are here!

LOCATION: /usr/share/hifam/

QUICK SETUP:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Copy to your home
cp -r /usr/share/hifam ~/hifam-config

# Create symlinks for dotfiles
mkdir -p ~/.config
ln -sf ~/hifam-config/nvim ~/.config/nvim
ln -sf ~/hifam-config/kitty ~/.config/kitty
ln -sf ~/hifam-config/hypr ~/.config/hypr

# Copy shell configs
cp ~/hifam-config/zshrc ~/.zshrc
cp ~/hifam-config/p10k.zsh ~/.p10k.zsh
mkdir -p ~/.config/tmux
cp ~/hifam-config/tmux.conf ~/.config/tmux/

# Setup keyd (keyboard remapping)
sudo cp ~/hifam-config/keyd/default.conf /etc/keyd/
sudo systemctl enable --now keyd

# Setup Plymouth boot splash
sudo plymouth-set-default-theme hifam
sudo mkinitcpio -P
# Reboot to see the boot splash

MANUAL SCRIPTS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cd ~/hifam-config/hifam-arch-scripts
./2-install-packages.sh
./6-setup-symlinks.sh
./8-zsh-setup.sh
# etc...

For more info: https://github.com/MontyTheSoftwareEngineer/hifam-arch
EOFREADME

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅ Copy Complete!                                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Your configs are now in: /usr/share/hifam"
echo ""
echo "Next steps:"
echo "  1. umount -R /mnt"
echo "  2. reboot"
echo ""
echo "After booting:"
echo "  • Read /usr/share/hifam/README.txt"
echo "  • Copy configs and run setup scripts as needed"
echo ""

exit 0
