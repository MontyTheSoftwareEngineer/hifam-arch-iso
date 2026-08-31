#!/bin/sh

echo "Setting up mouseless environment..."
sudo groupadd --system mouseless
sudo usermod -aG input,mouseless $USER

sudo tee /etc/udev/rules.d/99-mouseless-input.rules <<EOF
# Output: Virtual device creation
KERNEL=="uinput", GROUP="mouseless", MODE:="0660"
EOF

sudo modprobe uinput
echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf

sudo udevadm control --reload-rules && sudo udevadm trigger

echo "Installing required packages..."
flatpak install -y flathub org.gnome.Platform//50

# Add GPG-signed repo
flatpak remote-add --if-not-exists sonuscape \
  https://dl.sonuscape.net/flatpak/sonuscape.flatpakrepo

# Install mouseless
flatpak install -y sonuscape net.sonuscape.mouseless

mkdir -p ~/.var/app/net.sonuscape.mouseless/data/mouseless/configs
cp ~/OmarchyDotFiles/mouseless/config.yaml ~/.var/app/net.sonuscape.mouseless/data/mouseless/configs
