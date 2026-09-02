#!/bin/bash
# Copy HiFam configuration and post-install helpers into the installed system.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/hifam-config"
POSTINSTALL_DIR="$SCRIPT_DIR/postinstall"
MOUNT_POINT="${1:-/mnt}"

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

if [ ! -d "$CONFIG_DIR" ]; then
    echo "ERROR: HiFam config directory not found at $CONFIG_DIR"
    exit 1
fi

if [ ! -d "$POSTINSTALL_DIR" ]; then
    echo "ERROR: Post-install helper directory not found at $POSTINSTALL_DIR"
    exit 1
fi

if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo "ERROR: No installed system found at $MOUNT_POINT"
    exit 1
fi

echo "Copying HiFam configs to $MOUNT_POINT/usr/share/hifam..."
install -d "$MOUNT_POINT/usr/share/hifam"
cp -a "$CONFIG_DIR/." "$MOUNT_POINT/usr/share/hifam/"
find "$MOUNT_POINT/usr/share/hifam" -type f -name '*.sh' -exec chmod 0755 {} +

echo "Copying post-install helper scripts to $MOUNT_POINT/root/hifam-postinstall..."
install -d "$MOUNT_POINT/root/hifam-postinstall"
cp -a "$POSTINSTALL_DIR/." "$MOUNT_POINT/root/hifam-postinstall/"
find "$MOUNT_POINT/root/hifam-postinstall" -type f -name '*.sh' -exec chmod 0755 {} +

if [ -d "/usr/share/plymouth/themes/hifam" ]; then
    echo "Copying Plymouth theme..."
    install -d "$MOUNT_POINT/usr/share/plymouth/themes/hifam"
    cp -a /usr/share/plymouth/themes/hifam/. "$MOUNT_POINT/usr/share/plymouth/themes/hifam/"
fi

cat > "$MOUNT_POINT/usr/share/hifam/README.txt" <<'EOFREADME'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║  HiFam Arch Configuration Files                                  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Your HiFam dotfiles and support scripts are installed here:

  /usr/share/hifam

CONTENTS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• hifam-arch-scripts/  - Manual post-install scripts
• nvim/                - Neovim configuration
• kitty/               - Kitty terminal configuration
• hypr/                - Hyprland configuration
• fastfetch/           - Fastfetch configuration and custom logo
• fontconfig/          - Font aliases and defaults
• keyd/                - Keyboard remapping
• tmux/                - Tmux configuration
• mouseless/           - Mouseless configuration
• zshrc / p10k.zsh     - Shell configuration

AUTOMATED SETUP:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The live installer already copied and ran the chroot helper set:

  /root/hifam-postinstall/run.sh

If you need to rerun that automation from the installed system:

  sudo /root/hifam-postinstall/run.sh

MANUAL SETUP:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Copy configs to your home:
   cp -r /usr/share/hifam ~/hifam-config

2. Create the main config links:
   mkdir -p ~/.config/tmux
   ln -sf /usr/share/hifam/nvim ~/.config/nvim
   ln -sf /usr/share/hifam/kitty ~/.config/kitty
   ln -sf /usr/share/hifam/hypr ~/.config/hypr
   ln -sf /usr/share/hifam/fastfetch ~/.config/fastfetch
   ln -sf /usr/share/hifam/fontconfig ~/.config/fontconfig
   cp /usr/share/hifam/tmux/tmux.conf ~/.config/tmux/tmux.conf

3. Copy shell configs:
   cp /usr/share/hifam/zshrc ~/.zshrc
   cp /usr/share/hifam/p10k.zsh ~/.p10k.zsh

4. Optional manual scripts:
   cd ~/hifam-config/hifam-arch-scripts
   ./2-install-packages.sh
   ./6-setup-symlinks.sh
   ./8-zsh-setup.sh

For more info: https://github.com/MontyTheSoftwareEngineer/hifam-arch
EOFREADME

echo "✓ HiFam configs and helper scripts copied."
