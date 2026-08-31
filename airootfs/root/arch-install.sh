#!/bin/bash
# Interactive disk selection -> generates archinstall config -> runs archinstall.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/hifam-config"

BASE_CONFIG="$CONFIG_DIR/user_configuration.json"
CREDS_CONFIG="$CONFIG_DIR/user_credentials.json"
DEFAULT_HOSTNAME="$(jq -r '.hostname // "archlinux"' "$BASE_CONFIG")"

echo "╔════════════════════════════════════════╗"
echo "║       HiFam Arch Installer             ║"
echo "╚════════════════════════════════════════╝"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

for cmd in lsblk jq archinstall numfmt; do
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

echo "Available disks:"
echo ""

mapfile -t DISK_PATHS < <(lsblk -bdpn -o NAME -e 7,11)

if [ "${#DISK_PATHS[@]}" -eq 0 ]; then
    echo "No disks found."
    exit 1
fi

for i in "${!DISK_PATHS[@]}"; do
    disk_path="${DISK_PATHS[$i]}"
    disk_size_bytes="$(lsblk -bdn -o SIZE "$disk_path")"
    disk_model="$(lsblk -dn -o MODEL "$disk_path")"
    printf "%d) %s  %s  %s\n" \
        "$((i + 1))" \
        "$disk_path" \
        "$(numfmt --to=iec --suffix=B "$disk_size_bytes")" \
        "${disk_model:-Unknown model}"
done

echo ""

while true; do
    read -rp "Select installation disk [1-${#DISK_PATHS[@]}]: " DISK_NUMBER

    if [[ "$DISK_NUMBER" =~ ^[0-9]+$ ]] &&
       [ "$DISK_NUMBER" -ge 1 ] &&
       [ "$DISK_NUMBER" -le "${#DISK_PATHS[@]}" ]; then
        break
    fi

    echo "Invalid selection."
done

INSTALL_DISK="${DISK_PATHS[$((DISK_NUMBER - 1))]}"
DISK_SIZE_BYTES="$(lsblk -bdn -o SIZE "$INSTALL_DISK")"
DISK_SIZE_MIB=$((DISK_SIZE_BYTES / 1024 / 1024))
DISK_MODEL="$(lsblk -dn -o MODEL "$INSTALL_DISK")"

echo ""
echo "Selected disk:"
printf "  %s  %s  %s\n" \
    "$INSTALL_DISK" \
    "$(numfmt --to=iec --suffix=B "$DISK_SIZE_BYTES")" \
    "${DISK_MODEL:-Unknown model}"
echo ""

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

echo ""
while true; do
    read -rp "Hostname [$DEFAULT_HOSTNAME]: " HOSTNAME
    HOSTNAME="${HOSTNAME:-$DEFAULT_HOSTNAME}"

    if [[ "$HOSTNAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
        break
    fi

    echo "Invalid hostname. Use letters, numbers, and hyphens only."
done

EFI_UUID="$(cat /proc/sys/kernel/random/uuid)"
ROOT_UUID="$(cat /proc/sys/kernel/random/uuid)"

EFI_START_MIB=1
EFI_SIZE_MIB=1024
SWAP_SIZE_MIB=$((8 * 1024))
ROOT_MIN_SIZE_MIB=$((10 * 1024))
END_BUFFER_MIB=16
ROOT_START_MIB=$((EFI_START_MIB + EFI_SIZE_MIB))
MIN_REQUIRED_MIB=$((ROOT_START_MIB + ROOT_MIN_SIZE_MIB + END_BUFFER_MIB))

if [ "$SWAP_TYPE" = "partition" ]; then
    SWAP_UUID="$(cat /proc/sys/kernel/random/uuid)"
    SWAP_START_MIB=$ROOT_START_MIB
    ROOT_START_MIB=$((SWAP_START_MIB + SWAP_SIZE_MIB))
    MIN_REQUIRED_MIB=$((ROOT_START_MIB + ROOT_MIN_SIZE_MIB + END_BUFFER_MIB))
fi

if [ "$DISK_SIZE_MIB" -le "$MIN_REQUIRED_MIB" ]; then
    echo "ERROR: $INSTALL_DISK is too small for the selected layout."
    printf "Need more than %s MiB, but disk has %s MiB.\n" \
        "$MIN_REQUIRED_MIB" \
        "$DISK_SIZE_MIB"
    exit 1
fi

ROOT_SIZE_MIB=$((DISK_SIZE_MIB - ROOT_START_MIB - END_BUFFER_MIB))

if [ "$ROOT_SIZE_MIB" -lt "$ROOT_MIN_SIZE_MIB" ]; then
    echo "ERROR: Not enough remaining space for the root partition."
    printf "Root would be %s MiB after reserving install overhead, but at least %s MiB is required.\n" \
        "$ROOT_SIZE_MIB" \
        "$ROOT_MIN_SIZE_MIB"
    exit 1
fi

PARTITIONS_JSON="$(
    jq -n \
        --arg efi_uuid "$EFI_UUID" \
        --arg root_uuid "$ROOT_UUID" \
        --arg filesystem "$FILESYSTEM" \
        --arg swap_type "$SWAP_TYPE" \
        --arg swap_uuid "${SWAP_UUID:-}" \
        --argjson efi_start_mib "$EFI_START_MIB" \
        --argjson efi_size_mib "$EFI_SIZE_MIB" \
        --argjson swap_start_mib "${SWAP_START_MIB:-0}" \
        --argjson swap_size_mib "$SWAP_SIZE_MIB" \
        --argjson root_start_mib "$ROOT_START_MIB" \
        --argjson root_size_mib "$ROOT_SIZE_MIB" \
        '
        [
            {
                btrfs: [],
                dev_path: null,
                flags: ["boot", "esp"],
                fs_type: "fat32",
                mount_options: [],
                mountpoint: "/boot",
                obj_id: $efi_uuid,
                size: {
                    sector_size: {
                        unit: "B",
                        value: 512
                    },
                    unit: "MiB",
                    value: $efi_size_mib
                },
                start: {
                    sector_size: {
                        unit: "B",
                        value: 512
                    },
                    unit: "MiB",
                    value: $efi_start_mib
                },
                status: "create",
                type: "primary"
            }
        ]
        + (
            if $swap_type == "partition" then
                [
                    {
                        btrfs: [],
                        dev_path: null,
                        flags: [],
                        fs_type: "linux-swap",
                        mount_options: [],
                        mountpoint: null,
                        obj_id: $swap_uuid,
                        size: {
                            sector_size: {
                                unit: "B",
                                value: 512
                            },
                            unit: "MiB",
                            value: $swap_size_mib
                        },
                        start: {
                            sector_size: {
                                unit: "B",
                                value: 512
                            },
                            unit: "MiB",
                            value: $swap_start_mib
                        },
                        status: "create",
                        type: "primary"
                    }
                ]
            else
                []
            end
        )
        + [
            {
                btrfs: [],
                dev_path: null,
                flags: [],
                fs_type: $filesystem,
                mount_options: [],
                mountpoint: "/",
                obj_id: $root_uuid,
                size: {
                    sector_size: {
                        unit: "B",
                        value: 512
                    },
                    unit: "MiB",
                    value: $root_size_mib
                },
                start: {
                    sector_size: {
                        unit: "B",
                        value: 512
                    },
                    unit: "MiB",
                    value: $root_start_mib
                },
                status: "create",
                type: "primary"
            }
        ]
        '
)"

TEMP_CONFIG="$(mktemp /tmp/hifam-archinstall-XXXXXX.json)"
KEEP_TEMP_CONFIG=0

cleanup() {
    if [ "$KEEP_TEMP_CONFIG" -eq 0 ]; then
        rm -f "$TEMP_CONFIG"
    fi
}

trap cleanup EXIT

echo ""
echo "Generating archinstall configuration..."

jq \
    --arg disk "$INSTALL_DISK" \
    --argjson partitions "$PARTITIONS_JSON" \
    --arg swap_type "$SWAP_TYPE" \
    --arg hostname "$HOSTNAME" \
    '
    .script = "guided"
    |
    .silent = true
    |
    .hostname = $hostname
    |
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

if ! jq empty "$TEMP_CONFIG" >/dev/null 2>&1; then
    echo "ERROR: Generated JSON is invalid."
    cat "$TEMP_CONFIG"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║       Installation Configuration       ║"
echo "╠════════════════════════════════════════╣"
printf "║ Disk:       %-25s ║\n" "$INSTALL_DISK"
printf "║ Filesystem: %-25s ║\n" "$FILESYSTEM"
printf "║ Swap:       %-25s ║\n" "$SWAP_TYPE"
printf "║ Hostname:   %-25s ║\n" "$HOSTNAME"
echo "╚════════════════════════════════════════╝"
echo ""

echo "Generated disk configuration:"
echo ""
jq '.disk_config' "$TEMP_CONFIG"
echo ""

read -rp "Start Arch installation? [y/N]: " FINAL_CONFIRM

if [[ ! "$FINAL_CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "╔════════════════════════════════════════╗"
echo "║       Starting archinstall...          ║"
echo "╚════════════════════════════════════════╝"
echo ""

if archinstall --config "$TEMP_CONFIG" --creds "$CREDS_CONFIG" --silent; then
    INSTALL_EXIT=0
else
    INSTALL_EXIT=$?
fi

echo ""
echo "archinstall exited with code: $INSTALL_EXIT"

if [ "$INSTALL_EXIT" -ne 0 ]; then
    KEEP_TEMP_CONFIG=1
    echo ""
    echo "❌ Arch installation failed."
    echo ""
    echo "Generated configuration preserved at:"
    echo "  $TEMP_CONFIG"
    exit "$INSTALL_EXIT"
fi

echo ""
echo "✓ Arch installation completed successfully."
