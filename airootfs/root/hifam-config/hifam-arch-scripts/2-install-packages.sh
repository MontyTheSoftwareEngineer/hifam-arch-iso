#!/bin/sh
echo "Installing packages..."

pacman -S --needed --noconfirm aarch64-linux-gnu-gcc age aha bear \
    cmatrix dfu-util figlet flatpak fontconfig gimp github-cli go gparted \
    inkscape kitty lcov meld \
    nmap python-pip python-pipx python-pyserial \
    python-textual rust screen sl sops sqlitebrowser sshpass termscp unzip \
    xmlstarlet yazi yq zig zsh usbutils meson tmux base-devel libevent \
    fzf ripgrep gimp yazi repo openssh udiskie bear flatpak ncurses \
    git keyd zoxide jq gpu-screen-recorder 

echo "Installing Yay (AUR helper)..."
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm

cd /
rm -rf /tmp/yay

echo "Package installation complete!"
