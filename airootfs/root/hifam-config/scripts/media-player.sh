#!/bin/bash

status=$(playerctl status 2>/dev/null)

if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
    artist=$(playerctl metadata artist 2>/dev/null)
    title=$(playerctl metadata title 2>/dev/null)

    # Limit length to avoid waybar overflow
    if [ -n "$artist" ] && [ -n "$title" ]; then
        text="${artist} - ${title}"
    elif [ -n "$title" ]; then
        text="${title}"
    else
        text="Media Playing"
    fi

    # Truncate if too long
    if [ ${#text} -gt 40 ]; then
        text="${text:0:37}..."
    fi

    if [ "$status" = "Playing" ]; then
        icon="󰐊"
    else
        icon="󰏤"
    fi

    echo "{\"text\":\"$icon $text\", \"tooltip\":\"$artist - $title\", \"class\":\"$status\"}"
else
    echo "{\"text\":\"\", \"tooltip\":\"No media playing\", \"class\":\"stopped\"}"
fi

