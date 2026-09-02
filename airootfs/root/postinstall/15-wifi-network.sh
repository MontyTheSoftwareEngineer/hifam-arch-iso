#!/bin/bash

set -euo pipefail

WIFI_STAGING_FILE="/root/hifam-install-wifi.env"

if [ ! -f "$WIFI_STAGING_FILE" ]; then
    exit 0
fi

source "$WIFI_STAGING_FILE"

if [ -z "${WIFI_SSID:-}" ]; then
    echo "ERROR: Wi-Fi staging file is missing WIFI_SSID."
    exit 1
fi

pacman -S --needed --noconfirm networkmanager

install -d -m 0700 /etc/NetworkManager/system-connections

CONNECTION_UUID="$(cat /proc/sys/kernel/random/uuid)"
CONNECTION_FILE="/etc/NetworkManager/system-connections/hifam-wifi-${CONNECTION_UUID}.nmconnection"

{
    echo "[connection]"
    printf 'id=%s\n' "$WIFI_SSID"
    printf 'uuid=%s\n' "$CONNECTION_UUID"
    echo "type=wifi"
    echo "autoconnect=true"
    echo
    echo "[wifi]"
    echo "mode=infrastructure"
    printf 'ssid=%s\n' "$WIFI_SSID"
    echo
    if [ "${WIFI_OPEN:-0}" = "1" ]; then
        echo "[wifi-security]"
        echo "key-mgmt=none"
        echo
    else
        if [ -z "${WIFI_PASSPHRASE:-}" ]; then
            echo "ERROR: Wi-Fi staging file is missing WIFI_PASSPHRASE for a secured network."
            exit 1
        fi
        echo "[wifi-security]"
        echo "key-mgmt=wpa-psk"
        printf 'psk=%s\n' "$WIFI_PASSPHRASE"
        echo
    fi
    echo "[ipv4]"
    echo "method=auto"
    echo
    echo "[ipv6]"
    echo "method=auto"
} > "$CONNECTION_FILE"

chmod 0600 "$CONNECTION_FILE"

if [ -f /usr/lib/systemd/system/NetworkManager.service ]; then
    systemctl enable NetworkManager.service
fi

rm -f "$WIFI_STAGING_FILE"
