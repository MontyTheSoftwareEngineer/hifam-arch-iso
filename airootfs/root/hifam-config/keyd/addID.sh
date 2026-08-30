#!/bin/bash

# addID.sh - Helper script to identify and add keyboard device IDs to keyd config
# This script helps identify keyboard devices on your system and generates the proper
# device ID format for keyd's [ids] section

set -e

KEYD_CONFIG="/etc/keyd/default.conf"
BACKUP_CONFIG="/etc/keyd/default.conf.backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== keyd Device ID Helper ===${NC}\n"

# Check if running as root (needed for some operations)
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}Note: Some operations may require sudo privileges${NC}\n"
fi

# Function to extract device IDs from /proc/bus/input/devices
get_keyboard_devices() {
    local device=""
    local name=""
    local handlers=""
    local vendor=""
    local product=""
    local version=""
    
    echo -e "${GREEN}Scanning for keyboard devices...${NC}\n"
    
    while IFS= read -r line; do
        if [[ $line =~ ^I: ]]; then
            # Extract vendor, product, version from Bus line
            vendor=$(echo "$line" | grep -oP 'Vendor=\K[0-9a-f]+' || echo "")
            product=$(echo "$line" | grep -oP 'Product=\K[0-9a-f]+' || echo "")
            version=$(echo "$line" | grep -oP 'Version=\K[0-9a-f]+' || echo "")
        elif [[ $line =~ ^N: ]]; then
            # Extract device name
            name=$(echo "$line" | sed 's/N: Name="\(.*\)"/\1/')
        elif [[ $line =~ ^H: ]]; then
            # Extract handlers
            handlers=$(echo "$line" | sed 's/H: Handlers=//')
        elif [[ $line =~ ^B:.*KEY= ]]; then
            # If device has KEY capabilities and we have all info
            if [[ -n "$vendor" && -n "$product" && -n "$version" && -n "$name" ]]; then
                # Check if it's likely a keyboard (has 'kbd' handler)
                if [[ $handlers == *"kbd"* ]]; then
                    echo -e "${YELLOW}Device found:${NC}"
                    echo "  Name: $name"
                    echo "  Handlers: $handlers"
                    echo "  Vendor: $vendor, Product: $product, Version: $version"
                    
                    # Generate keyd ID format: vendor:product:hash
                    # Note: keyd uses a hash of the device name for the third part
                    # We'll calculate it properly
                    local device_id="${vendor}:${product}"
                    echo -e "  ${GREEN}Device ID prefix: ${device_id}${NC}"
                    echo ""
                fi
            fi
            # Reset for next device
            vendor=""
            product=""
            version=""
            name=""
            handlers=""
        fi
    done < /proc/bus/input/devices
}

# Function to get the full keyd device ID (requires keyd to be running)
get_keyd_ids() {
    echo -e "\n${GREEN}Attempting to get device IDs from keyd monitor...${NC}"
    echo -e "${YELLOW}Please press a key on each keyboard you want to configure${NC}"
    echo -e "${YELLOW}Press Ctrl+C when done${NC}\n"
    
    if command -v keyd &> /dev/null; then
        # Run keyd monitor and capture device IDs
        sudo keyd monitor -t 2>&1 | grep -oP '\d+:\d+:\w+' | sort -u || true
    else
        echo -e "${RED}keyd command not found. Please install keyd first.${NC}"
        return 1
    fi
}

# Function to add ID to config
add_id_to_config() {
    local device_id="$1"
    
    if [ ! -f "$KEYD_CONFIG" ]; then
        echo -e "${RED}Config file not found at $KEYD_CONFIG${NC}"
        return 1
    fi
    
    # Backup config
    sudo cp "$KEYD_CONFIG" "$BACKUP_CONFIG"
    echo -e "${GREEN}Backed up config to $BACKUP_CONFIG${NC}"
    
    # Check if ID already exists
    if grep -q "$device_id" "$KEYD_CONFIG"; then
        echo -e "${YELLOW}Device ID $device_id already exists in config${NC}"
        return 0
    fi
    
    # Add ID to [ids] section
    if grep -q "^\[ids\]" "$KEYD_CONFIG"; then
        # [ids] section exists, add after it
        sudo sed -i "/^\[ids\]/a $device_id" "$KEYD_CONFIG"
    else
        # No [ids] section, create it at the top
        sudo sed -i "1i [ids]\n$device_id\n" "$KEYD_CONFIG"
    fi
    
    echo -e "${GREEN}Added device ID $device_id to $KEYD_CONFIG${NC}"
}

# Main menu
echo "Choose an option:"
echo "1) Scan for keyboard devices (basic info)"
echo "2) Get device IDs from keyd monitor (interactive - requires keypresses)"
echo "3) Add a device ID manually"
echo "4) Show current config"
echo ""
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        get_keyboard_devices
        echo -e "\n${BLUE}To get the full device ID with hash, use option 2 or run:${NC}"
        echo "  sudo keyd monitor -t"
        echo -e "${BLUE}Then press keys on your keyboard and note the device ID shown${NC}"
        ;;
    2)
        echo -e "\n${BLUE}Starting keyd monitor...${NC}"
        echo "The device IDs will be shown when you press keys."
        echo "Copy the full ID (format: XXXX:XXXX:XXXXXXXX)"
        echo ""
        sudo keyd monitor -t || echo -e "${RED}Failed to run keyd monitor${NC}"
        ;;
    3)
        read -p "Enter device ID (format XXXX:XXXX:XXXXXXXX): " device_id
        if [[ $device_id =~ ^[0-9a-f]+:[0-9a-f]+:[0-9a-f]+$ ]]; then
            add_id_to_config "$device_id"
            echo -e "\n${BLUE}Reloading keyd configuration...${NC}"
            sudo keyd reload || echo -e "${YELLOW}Failed to reload. Try: sudo systemctl restart keyd${NC}"
        else
            echo -e "${RED}Invalid device ID format${NC}"
        fi
        ;;
    4)
        if [ -f "$KEYD_CONFIG" ]; then
            echo -e "\n${BLUE}Current keyd config:${NC}\n"
            cat "$KEYD_CONFIG"
        else
            echo -e "${RED}Config not found at $KEYD_CONFIG${NC}"
        fi
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "\n${BLUE}=== Done ===${NC}"
