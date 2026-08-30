#!/bin/bash
# Check lid state on Hyprland startup and set laptop display accordingly
# Lid open/close events are handled by Hyprland's bindl in bindings.conf

sleep 1  # Give Hyprland a moment to fully initialize

LID_STATE=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | awk '{print $2}')

if [ "$LID_STATE" = "closed" ]; then
    notify-send -u low "Clamshell Mode" "External monitor active. Laptop screen disabled." -i video-display
    hyprctl keyword monitor "eDP-1, disable"
elif [ "$LID_STATE" = "open" ]; then
    notify-send -u low "Laptop Mode" "Laptop screen enabled." -i computer
    hyprctl keyword monitor "eDP-1, preferred, auto, 1"
fi
