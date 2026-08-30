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
cd /tmp
rm -rf yay
git clone https://aur.archlinux.org/yay.git
cd yay
# Run makepkg as the user, not root
if [ -n "$SUDO_USER" ]; then
    sudo -u "$SUDO_USER" makepkg -si --noconfirm
elif [ "$EUID" -eq 0 ]; then
    # If running as root without SUDO_USER, create temp user
    useradd -m -G wheel tempbuilduser 2>/dev/null || true
    chown -R tempbuilduser:tempbuilduser .
    sudo -u tempbuilduser makepkg -si --noconfirm
    userdel -r tempbuilduser 2>/dev/null || true
else
    makepkg -si --noconfirm
fi

cd /
rm -rf /tmp/yay

echo "Package installation complete!"
