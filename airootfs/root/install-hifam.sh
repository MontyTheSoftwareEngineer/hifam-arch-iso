#!/bin/bash
# HiFam Arch Installer Wrapper
# This script runs archinstall with your custom configuration
# and then executes post-installation customization in the chroot

set -e

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
echo "2. Copy HiFam configs to the new system"
echo "3. Run post-installation scripts in chroot"
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
if [ $INSTALL_EXIT -ne 0 ]; then
    echo "archinstall failed with exit code $INSTALL_EXIT"
    echo "Please review the errors and try again"
    exit $INSTALL_EXIT
fi

# Find the mount point (usually /mnt)
MOUNT_POINT="/mnt"
if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo "Looking for installation mount point..."
    for mp in /mnt /install /target; do
        if [ -d "$mp/etc" ]; then
            MOUNT_POINT="$mp"
            break
        fi
    done
fi

if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo "Error: Could not find mounted installation!"
    echo "Please mount your new system and run the post-install script manually:"
    echo "  arch-chroot /mnt /root/post-install.sh"
    exit 1
fi

echo ""
echo "=== Installation found at: $MOUNT_POINT ==="

# Copy HiFam configs to the new system
echo "Copying HiFam configuration to new system..."
mkdir -p "$MOUNT_POINT/root/hifam-config"
cp -r "$CONFIG_DIR"/* "$MOUNT_POINT/root/hifam-config/"

# Copy the post-install script
cp "$SCRIPT_DIR/post-install.sh" "$MOUNT_POINT/root/"
chmod +x "$MOUNT_POINT/root/post-install.sh"

# Run post-installation in chroot
echo ""
echo "=== Running post-installation setup ==="
read -p "Run post-installation scripts now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    arch-chroot "$MOUNT_POINT" /root/post-install.sh
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║  Installation Complete!                 ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "You can now:"
    echo "  • umount -R $MOUNT_POINT"
    echo "  • reboot"
else
    echo ""
    echo "Post-installation skipped. You can run it later with:"
    echo "  arch-chroot $MOUNT_POINT /root/post-install.sh"
fi

echo ""
echo "Configuration files are available in /root/hifam-config"
echo "Installation logs are in /var/log/hifam-*.log"

exit 0
