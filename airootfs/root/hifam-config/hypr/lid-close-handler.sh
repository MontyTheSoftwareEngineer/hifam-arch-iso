#!/bin/bash
# Handle lid close - suspend only if no external monitors are active

# Check if any external monitors are active (not eDP-1)
EXTERNAL_MONITORS=$(hyprctl monitors -j | jq -r '.[] | select(.name != "eDP-1") | .name' | wc -l)

if [ "$EXTERNAL_MONITORS" -gt 0 ]; then
    # External monitor(s) connected - do nothing (clamshell handled elsewhere)
    notify-send -u low "Lid Closed" "External display connected, doing nothing." -i video-display
else
    # No external monitors - suspend the system
    systemctl suspend
fi
