#!/bin/bash

set -euo pipefail

have_internet() {
    curl -fsI --connect-timeout 5 https://archlinux.org >/dev/null 2>&1
}

list_wireless_interfaces() {
    iw dev | awk '$1 == "Interface" { print $2 }'
}

ensure_iwd_running() {
    systemctl start iwd.service >/dev/null 2>&1 || true
}

connect_open_network() {
    local iface="$1"
    local ssid="$2"

    iwctl station "$iface" connect "$ssid"
}

connect_secure_network() {
    local iface="$1"
    local ssid="$2"
    local passphrase="$3"

    iwctl --passphrase "$passphrase" station "$iface" connect "$ssid"
}

echo "╔════════════════════════════════════════╗"
echo "║        HiFam Wi-Fi Connection         ║"
echo "╚════════════════════════════════════════╝"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

for cmd in curl iw iwctl systemctl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: '$cmd' is required but was not found."
        exit 1
    fi
done

if have_internet; then
    echo "Internet connectivity is already working."
    exit 0
fi

ensure_iwd_running

mapfile -t WIFI_INTERFACES < <(list_wireless_interfaces)

if [ "${#WIFI_INTERFACES[@]}" -eq 0 ]; then
    echo "No wireless interfaces were detected."
    echo "If you prefer, run 'iwctl' manually in another shell."
    exit 1
fi

echo "Wireless interfaces:"
for i in "${!WIFI_INTERFACES[@]}"; do
    printf "%d) %s\n" "$((i + 1))" "${WIFI_INTERFACES[$i]}"
done
echo ""

while true; do
    read -rp "Select Wi-Fi interface [1-${#WIFI_INTERFACES[@]}]: " WIFI_NUMBER
    if [[ "$WIFI_NUMBER" =~ ^[0-9]+$ ]] &&
       [ "$WIFI_NUMBER" -ge 1 ] &&
       [ "$WIFI_NUMBER" -le "${#WIFI_INTERFACES[@]}" ]; then
        break
    fi
    echo "Invalid selection."
done

WIFI_INTERFACE="${WIFI_INTERFACES[$((WIFI_NUMBER - 1))]}"

echo ""
echo "Scanning with $WIFI_INTERFACE..."
iwctl station "$WIFI_INTERFACE" scan
sleep 2
echo ""
echo "Available networks:"
iwctl station "$WIFI_INTERFACE" get-networks || true
echo ""
echo "Enter the SSID exactly as shown above."
read -rp "SSID: " WIFI_SSID

if [ -z "$WIFI_SSID" ]; then
    echo "SSID cannot be empty."
    exit 1
fi

read -rp "Is the network open (no password)? [y/N]: " OPEN_REPLY

if [[ "$OPEN_REPLY" =~ ^[Yy]$ ]]; then
    connect_open_network "$WIFI_INTERFACE" "$WIFI_SSID"
else
    read -rsp "Wi-Fi passphrase: " WIFI_PASSPHRASE
    echo
    if [ -z "$WIFI_PASSPHRASE" ]; then
        echo "Passphrase cannot be empty for a secured network."
        exit 1
    fi
    connect_secure_network "$WIFI_INTERFACE" "$WIFI_SSID" "$WIFI_PASSPHRASE"
    unset WIFI_PASSPHRASE
fi

echo ""
echo "Waiting for connectivity..."
for _ in $(seq 1 10); do
    if have_internet; then
        echo "✓ Wi-Fi connected."
        exit 0
    fi
    sleep 2
done

echo "Wi-Fi connected, but internet access could not be confirmed yet."
echo "You can continue with the install or verify manually with 'iwctl' or 'ping'."
