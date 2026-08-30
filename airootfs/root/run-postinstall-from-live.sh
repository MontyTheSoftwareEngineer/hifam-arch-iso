#!/bin/bash
# Run Post-Installation Setup from Installed System
# Use this if post-install.sh wasn't run during installation

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  HiFam Arch - Post-Installation Setup (From Live System)  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in the live environment
if [ ! -d "/root/hifam-config" ]; then
    echo "ERROR: This script must be run from the live USB environment!"
    echo ""
    echo "Boot back into the live USB and run:"
    echo "  mount /dev/sdXY /mnt  # Your root partition"
    echo "  mount /dev/sdXZ /mnt/boot  # Your ESP partition if separate"
    echo "  arch-chroot /mnt"
    echo "  # Then copy and run this script from inside chroot"
    exit 1
fi

# Check if already mounted
if [ ! -d "/mnt/etc" ]; then
    echo "ERROR: No system mounted at /mnt"
    echo ""
    echo "Mount your installed system first:"
    lsblk -f
    echo ""
    read -p "Enter root partition (e.g., /dev/sda2): " ROOT_PART
    read -p "Enter ESP/boot partition (e.g., /dev/sda1): " BOOT_PART
    
    if [ -b "$ROOT_PART" ]; then
        mount "$ROOT_PART" /mnt
        if [ -b "$BOOT_PART" ]; then
            mkdir -p /mnt/boot
            mount "$BOOT_PART" /mnt/boot
        fi
        echo "Mounted. Now running arch-chroot..."
    else
        echo "Invalid partition"
        exit 1
    fi
fi

# Copy configs to the installed system
echo "Copying HiFam configs to installed system..."
mkdir -p /mnt/root/hifam-config
cp -r /root/hifam-config/* /mnt/root/hifam-config/

# Copy the post-install script
cp /root/post-install.sh /mnt/root/
chmod +x /mnt/root/post-install.sh

echo ""
echo "Entering chroot to run post-installation..."
arch-chroot /mnt /root/post-install.sh

echo ""
echo "✅ Post-installation complete!"
echo ""
echo "You can now:"
echo "  • exit"
echo "  • umount -R /mnt"
echo "  • reboot"
