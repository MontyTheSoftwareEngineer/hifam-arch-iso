#!/bin/sh
echo "Installing packages..."

sudo pacman -S --needed --noconfirm aarch64-linux-gnu-gcc age aha bear \
    cmatrix dfu-util figlet flatpak fontconfig gimp github-cli go gparted \
    inkscape kitty lcov lib32-libice lib32-libjpeg-turbo lib32-libsm meld \
    nmap python-pip python-pipx python-pyserial python-terminaltexteffects \
    python-textual rust screen sl sops sqlitebrowser sshpass termscp unzip \
    xmlstarlet yazi yq zig zsh usbutils meson tmux base-devel libevent ncurses\
    fzf ripgrep termscp gimp yazi repo openssh udiskie dfu-util bear flatpak \
    git keyd zoxide jq gpu-screen-recorder

echo "Installing Yay"
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
