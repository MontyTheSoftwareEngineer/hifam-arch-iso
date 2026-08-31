#!/bin/bash
# HiFam Arch Installer Wrapper
# Interactive disk selection -> generates archinstall config -> runs archinstall

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/hifam-config"

BASE_CONFIG="$CONFIG_DIR/user_configuration.json"
CREDS_CONFIG="$CONFIG_DIR/user_credentials.json"

echo "╔════════════════════════════════════════╗"
echo "║       HiFam Arch Installer             ║"
echo "╚════════════════════════════════════════╝"
echo ""

# =========================================================
# Root check
# =========================================================

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

# =========================================================
# Check dependencies
# =========================================================

for cmd in lsblk jq archinstall; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: '$cmd' is required but was not found."
        exit 1
    fi
done

if [ ! -f "$BASE_CONFIG" ]; then
    echo "ERROR: Configuration file not found:"
    echo "  $BASE_CONFIG"
    exit 1
fi

if [ ! -f "$CREDS_CONFIG" ]; then
    echo "ERROR: Credentials file not found:"
    echo "  $CREDS_CONFIG"
    exit 1
fi

# =========================================================
# Find available disks
# =========================================================

echo "Available disks:"
echo ""

mapfile -t DISKS < <(
    lsblk -dpno NAME,SIZE,MODEL \
        -e 7,11
)

if [ "${#DISKS[@]}" -eq 0 ]; then
    echo "No disks found."
    exit 1
fi

for i in "${!DISKS[@]}"; do
    printf "%d) %s\n" "$((i + 1))" "${DISKS[$i]}"
done

echo ""

# =========================================================
# Select disk
# =========================================================

while true; do
    read -rp "Select installation disk [1-${#DISKS[@]}]: " DISK_NUMBER

    if [[ "$DISK_NUMBER" =~ ^[0-9]+$ ]] &&
       [ "$DISK_NUMBER" -ge 1 ] &&
       [ "$DISK_NUMBER" -le "${#DISKS[@]}" ]; then
        break
    fi

    echo "Invalid selection."
done

SELECTED_LINE="${DISKS[$((DISK_NUMBER - 1))]}"
INSTALL_DISK="$(echo "$SELECTED_LINE" | awk '{print $1}')"

echo ""
echo "Selected disk:"
echo "  $SELECTED_LINE"
echo ""

# =========================================================
# Destructive warning
# =========================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                         WARNING                            ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║                                                            ║"
echo "║  ALL DATA ON THIS DISK WILL BE ERASED.                    ║"
echo "║                                                            ║"
printf "║  %-58s ║\n" "$INSTALL_DISK"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

read -rp "Type ERASE to continue: " CONFIRM

if [ "$CONFIRM" != "ERASE" ]; then
    echo ""
    echo "Installation cancelled."
    exit 0
fi

# =========================================================
# Filesystem selection
# =========================================================

echo ""
echo "Filesystem:"
echo ""
echo "1) btrfs"
echo "2) ext4"
echo ""

while true; do
    read -rp "Select [1-2]: " FS_CHOICE

    case "$FS_CHOICE" in
        1)
            FILESYSTEM="btrfs"
            break
            ;;
        2)
            FILESYSTEM="ext4"
            break
            ;;
        *)
            echo "Invalid selection."
            ;;
    esac
done

# =========================================================
# Swap selection
# =========================================================

echo ""
echo "Swap:"
echo ""
echo "1) zram"
echo "2) swap partition"
echo "3) none"
echo ""

while true; do
    read -rp "Select [1-3]: " SWAP_CHOICE

    case "$SWAP_CHOICE" in
        1)
            SWAP_TYPE="zram"
            break
            ;;
        2)
            SWAP_TYPE="partition"
            break
            ;;
        3)
            SWAP_TYPE="none"
            break
            ;;
        *)
            echo "Invalid selection."
            ;;
    esac
done

# =========================================================
# Generate UUIDs
# =========================================================

EFI_UUID="$(cat /proc/sys/kernel/random/uuid)"
ROOT_UUID="$(cat /proc/sys/kernel/random/uuid)"

if [ "$SWAP_TYPE" = "partition" ]; then
    SWAP_UUID="$(cat /proc/sys/kernel/random/uuid)"
fi

# =========================================================
# Create partition configuration
# =========================================================

EFI_PARTITION='
{
    "btrfs": [],
    "dev_path": null,
    "flags": [
        "boot",
        "esp"
    ],
    "fs_type": "fat32",
    "mount_options": [],
    "mountpoint": "/boot",
    "obj_id": "'"$EFI_UUID"'",
    "size": {
        "sector_size": {
            "unit": "B",
            "value": 512
        },
        "unit": "MiB",
        "value": 1024
    },
    "start": {
        "sector_size": {
            "unit": "B",
            "value": 512
        },
        "unit": "MiB",
        "value": 1
    },
    "status": "create",
    "type": "primary"
}
'

# =========================================================
# Root partition
# =========================================================

ROOT_PARTITION='
{
    "btrfs": [],
    "dev_path": null,
    "flags": [],
    "fs_type": "'"$FILESYSTEM"'",
    "mount_options": [],
    "mountpoint": "/",
    "obj_id": "'"$ROOT_UUID"'",
    "size": {
        "sector_size": {
            "unit": "B",
            "value": 512
        },
        "unit": "GiB",
        "value": 999999
    },
    "start": {
        "sector_size": {
            "unit": "B",
            "value": 512
        },
        "unit": "MiB",
        "value": 1025
    },
    "status": "create",
    "type": "primary"
}
'

# =========================================================
# Build disk_config
# =========================================================

if [ "$SWAP_TYPE" = "partition" ]; then

    SWAP_PARTITION='
    {
        "btrfs": [],
        "dev_path": null,
        "flags": [],
        "fs_type": "linux-swap",
        "mount_options": [],
        "mountpoint": null,
        "obj_id": "'"$SWAP_UUID"'",
        "size": {
            "sector_size": {
                "unit": "B",
                "value": 512
            },
            "unit": "GiB",
            "value": 8
        },
        "start": {
            "sector_size": {
                "unit": "B",
                "value": 512
            },
            "unit": "MiB",
            "value": 1025
        },
        "status": "create",
        "type": "primary"
    }
    '

    # For a swap partition we need root to come after it.
    ROOT_START="9217"

    ROOT_PARTITION='
    {
        "btrfs": [],
        "dev_path": null,
        "flags": [],
        "fs_type": "'"$FILESYSTEM"'",
        "mount_options": [],
        "mountpoint": "/",
        "obj_id": "'"$ROOT_UUID"'",
        "size": {
            "sector_size": {
                "unit": "B",
                "value": 999999
            },
            "unit": "GiB",
            "value": 999999
        },
        "start": {
            "sector_size": {
                "unit": "B",
                "value": 512
            },
            "unit": "MiB",
            "value": "'"$ROOT_START"'"
        },
        "status": "create",
        "type": "primary"
    }
    '

    PARTITIONS="$EFI_PARTITION,$SWAP_PARTITION,$ROOT_PARTITION"

else

    PARTITIONS="$EFI_PARTITION,$ROOT_PARTITION"

fi

# =========================================================
# Generate temporary configuration
# =========================================================

TEMP_CONFIG="$(mktemp /tmp/hifam-archinstall-XXXXXX.json)"

trap 'rm -f "$TEMP_CONFIG"' EXIT

echo ""
echo "Generating archinstall configuration..."

jq \
    --arg disk "$INSTALL_DISK" \
    --argjson partitions "[$PARTITIONS]" \
    --arg swap_type "$SWAP_TYPE" \
    --arg filesystem "$FILESYSTEM" \
    '
    .disk_config = {
        "config_type": "default_layout",
        "device_modifications": [
            {
                "device": $disk,
                "partitions": $partitions,
                "wipe": true
            }
        ]
    }
    |
    .swap = {
        "algorithm": "zstd",
        "enabled": ($swap_type != "none")
    }
    ' \
    "$BASE_CONFIG" > "$TEMP_CONFIG"

# =========================================================
# Validate generated JSON
# =========================================================

if ! jq empty "$TEMP_CONFIG" >/dev/null 2>&1; then
    echo "ERROR: Generated JSON is invalid."
    cat "$TEMP_CONFIG"
    exit 1
fi

# =========================================================
# Display final configuration
# =========================================================

echo ""
echo "╔════════════════════════════════════════╗"
echo "║       Installation Configuration       ║"
echo "╠════════════════════════════════════════╣"
printf "║ Disk:       %-25s ║\n" "$INSTALL_DISK"
printf "║ Filesystem: %-25s ║\n" "$FILESYSTEM"
printf "║ Swap:       %-25s ║\n" "$SWAP_TYPE"
echo "╚════════════════════════════════════════╝"
echo ""

echo "Generated disk configuration:"
echo ""

jq '.disk_config' "$TEMP_CONFIG"

echo ""

# =========================================================
# Final confirmation
# =========================================================

read -rp "Start Arch installation? [y/N]: " FINAL_CONFIRM

if [[ ! "$FINAL_CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# =========================================================
# Run archinstall
# =========================================================

echo ""
echo "╔════════════════════════════════════════╗"
echo "║       Starting archinstall...          ║"
echo "╚════════════════════════════════════════╝"
echo ""

archinstall \
    --config "$TEMP_CONFIG" \
    --creds "$CREDS_CONFIG"

INSTALL_EXIT=$?

echo ""
echo "archinstall exited with code: $INSTALL_EXIT"

if [ "$INSTALL_EXIT" -ne 0 ]; then
    echo ""
    echo "❌ Arch installation failed."
    echo ""
    echo "The generated configuration was:"
    echo "$TEMP_CONFIG"
    exit "$INSTALL_EXIT"
fi

echo ""
echo "✓ Arch installation completed successfully."

