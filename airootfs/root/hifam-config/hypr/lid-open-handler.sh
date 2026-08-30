#!/bin/bash
# Handle lid open - wake display if needed, screen re-enabling handled elsewhere

# Give the system a moment to fully wake from suspend
sleep 0.5

# Check if any external monitors are active (not eDP-1)
EXTERNAL_MONITORS=$(hyprctl monitors -j | jq -r '.[] | select(.name != "eDP-1") | .name' | wc -l)

if [ "$EXTERNAL_MONITORS" -gt 0 ]; then
    # External monitor(s) connected - do nothing
    notify-send -u low "Lid Opened" "External display connected, doing nothing." -i video-display
else
    # No external monitors - wake displays if needed (screen re-enabling handled elsewhere)
    hyprctl dispatch dpms on
    
    notify-send -u low "Lid Opened" "Display woken." -i computer
fi
