#!/bin/bash
# HiFam post-install orchestrator run from the live ISO.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_mount_point() {
    local candidate

    for candidate in /mnt /install /target; do
        if [ -d "$candidate/etc" ]; then
            MOUNT_POINT="$candidate"
            return 0
        fi
    done

    return 1
}

mount_installed_system() {
    local root_part boot_part

    echo ""
    echo "Could not find a mounted installation."
    lsblk -f
    echo ""

    read -rp "Enter your root partition (for example /dev/sda2) or 'skip': " root_part

    if [ "$root_part" = "skip" ]; then
        echo ""
        echo "Skipping automated post-install."
        echo "To resume later from the live ISO:"
        echo "  1. Mount your root partition at /mnt"
        echo "  2. Mount your ESP at /mnt/boot if needed"
        echo "  3. Run /root/post-install.sh"
        exit 0
    fi

    if [ ! -b "$root_part" ]; then
        echo "ERROR: $root_part is not a valid block device."
        exit 1
    fi

    mount "$root_part" /mnt

    read -rp "Enter your boot/ESP partition or 'skip': " boot_part
    if [ "$boot_part" != "skip" ]; then
        if [ ! -b "$boot_part" ]; then
            echo "ERROR: $boot_part is not a valid block device."
            exit 1
        fi

        mkdir -p /mnt/boot
        mount "$boot_part" /mnt/boot
    fi

    MOUNT_POINT="/mnt"
}

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

echo "╔════════════════════════════════════════╗"
echo "║     HiFam Arch Post-Installation       ║"
echo "╚════════════════════════════════════════╝"

if ! find_mount_point; then
    mount_installed_system
fi

if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo "ERROR: No installed system found at $MOUNT_POINT"
    exit 1
fi

echo ""
echo "Using installation at: $MOUNT_POINT"

"$SCRIPT_DIR/copy-hifam-configs.sh" "$MOUNT_POINT"

echo ""
echo "Running chrooted post-install scripts..."
arch-chroot "$MOUNT_POINT" /root/hifam-postinstall/run.sh

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ Installation Complete!             ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. umount -R $MOUNT_POINT"
echo "  2. reboot"
echo ""
echo "After booting into your new system:"
echo "  • HiFam configs are in /usr/share/hifam"
echo "  • The chroot helper scripts are in /root/hifam-postinstall"
echo "  • Read /usr/share/hifam/README.txt for manual follow-up"
