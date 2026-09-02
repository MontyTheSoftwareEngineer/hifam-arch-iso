#!/bin/bash
# HiFam post-install orchestrator run from the live ISO.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_START_FILE="/tmp/hifam-install-start-epoch"
WIFI_STAGING_FILE="/tmp/hifam-install-wifi.env"

format_duration() {
    local total_seconds="$1"
    local hours minutes seconds

    hours=$((total_seconds / 3600))
    minutes=$(((total_seconds % 3600) / 60))
    seconds=$((total_seconds % 60))

    if [ "$hours" -gt 0 ]; then
        printf '%dh %dm %ds' "$hours" "$minutes" "$seconds"
    elif [ "$minutes" -gt 0 ]; then
        printf '%dm %ds' "$minutes" "$seconds"
    else
        printf '%ds' "$seconds"
    fi
}

show_install_duration() {
    local start_epoch end_epoch elapsed

    if [ ! -f "$INSTALL_START_FILE" ]; then
        return 0
    fi

    start_epoch="$(cat "$INSTALL_START_FILE" 2>/dev/null || true)"
    if [[ ! "$start_epoch" =~ ^[0-9]+$ ]]; then
        return 0
    fi

    end_epoch="$(date +%s)"
    if [ "$end_epoch" -lt "$start_epoch" ]; then
        return 0
    fi

    elapsed=$((end_epoch - start_epoch))
    echo "Total installation time: $(format_duration "$elapsed")"
}

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

if [ -f "$WIFI_STAGING_FILE" ]; then
    echo "Staging Wi-Fi credentials for the installed system..."
    install -D -m 0600 "$WIFI_STAGING_FILE" "$MOUNT_POINT/root/hifam-install-wifi.env"
fi

"$SCRIPT_DIR/copy-hifam-configs.sh" "$MOUNT_POINT"

echo ""
echo "Running chrooted post-install scripts..."
arch-chroot "$MOUNT_POINT" /root/hifam-postinstall/run.sh

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ Installation Complete!             ║"
echo "╚════════════════════════════════════════╝"
echo ""
show_install_duration
echo ""

read -rp "Reboot now? [y/N]: " REBOOT_CONFIRM

if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Unmounting $MOUNT_POINT and rebooting..."
    umount -R "$MOUNT_POINT"
    reboot
fi

echo "Next steps:"
echo "  1. umount -R $MOUNT_POINT"
echo "  2. reboot"
echo ""
echo "After booting into your new system:"
echo "  • HiFam configs are in /usr/share/hifam"
echo "  • The chroot helper scripts are in /root/hifam-postinstall"
echo "  • Read /usr/share/hifam/README.txt for manual follow-up"
