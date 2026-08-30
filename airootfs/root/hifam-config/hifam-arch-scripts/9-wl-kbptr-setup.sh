#!/bin/sh

echo "Setting up wl-kbptr"

echo "Installing keyd"
sudo pacman -S keyd

echo "Please enter the keyboard device ID (e.g., 0001:0001:3c78431b):"
read keyboard_id

if [ -n "$keyboard_id" ]; then
    config_file="../keyd/default.conf"
    if grep -q "^\[ids\]" "$config_file"; then
        sed -i "/^\[ids\]/a $keyboard_id" "$config_file"
        echo "Added keyboard ID $keyboard_id to $config_file"
    else
        echo "Warning: Could not find [ids] section in $config_file"
    fi
else
    echo "No keyboard ID provided, skipping configuration update"
fi

git clone https://github.com/DereckAn/wl-kbptr.git ~/wl-kbptr
cd ~/wl-kbptr
git checkout fix/opencv5
meson setup build --buildtype=release -Dopencv=enabled
meson compile -C build
sudo cp build/wl-kbptr /usr/bin
