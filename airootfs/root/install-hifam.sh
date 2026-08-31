#!/bin/bash
# HiFam Arch Installer Wrapper
# This script runs archinstall with your custom configuration
# and copies your configs to /usr/share/hifam for manual setup later

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$SCRIPT_DIR/hifam-config"

echo "╔════════════════════════════════════════╗"
echo "║   HiFam Arch Linux Installation        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

# Check for config files
if [ ! -f "$CONFIG_DIR/user_configuration.json" ]; then
    echo "Warning: user_configuration.json not found!"
    echo "Expected at: $CONFIG_DIR/user_configuration.json"
    echo ""
    read -p "Continue with manual archinstall configuration? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    USE_CONFIG=false
else
    USE_CONFIG=true
fi


# Show what will be done
echo "Installation plan:"
echo "1. Run archinstall with your configuration"
echo "2. Copy HiFam configs to /usr/share/hifam in the new system"
echo "3. You can manually run setup scripts after booting"
echo ""
read -p "Proceed with installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Run archinstall
echo ""
echo "=== Starting archinstall ==="
if [ "$USE_CONFIG" = true ]; then
    archinstall --config "$CONFIG_DIR/user_configuration.json" --creds "$CONFIG_DIR/user_credentials.json"
else
    archinstall
fi

INSTALL_EXIT=$?
echo ""
echo "archinstall exited with code: $INSTALL_EXIT"
sleep 2

# Find the mount point (usually /mnt)
MOUNT_POINT="/mnt"
if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo "Looking for installation mount point..."
    for mp in /mnt /install /target; do
        if [ -d "$mp/etc" ]; then
            MOUNT_POINT="$mp"
            echo "Found at: $mp"
            break
        fi
    done
fi

if [ ! -d "$MOUNT_POINT/etc" ]; then
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "WARNING: Could not find mounted installation at /mnt!"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "archinstall may have unmounted the system."
    lsblk -f
    echo ""
    read -p "Enter your root partition (e.g., /dev/sda2) or 'skip': " ROOT_PART
    
    if [ "$ROOT_PART" != "skip" ] && [ -b "$ROOT_PART" ]; then
        echo "Mounting $ROOT_PART to /mnt..."
        mount "$ROOT_PART" /mnt || { echo "Mount failed!"; exit 1; }
        
        read -p "Enter boot/ESP partition (e.g., /dev/sda1) or 'skip': " BOOT_PART
        if [ "$BOOT_PART" != "skip" ] && [ -b "$BOOT_PART" ]; then
            mkdir -p /mnt/boot
            mount "$BOOT_PART" /mnt/boot
        fi
        
        MOUNT_POINT="/mnt"
    else
        echo ""
        echo "Skipping config copy. To copy later:"
        echo "  1. Boot back to live USB"
        echo "  2. Mount your partitions to /mnt"
        echo "  3. mkdir -p /mnt/usr/share/hifam"
        echo "  4. cp -r /root/hifam-config/* /mnt/usr/share/hifam/"
        exit 0
    fi
fi

echo ""
echo "=== Installation found at: $MOUNT_POINT ==="

# Copy HiFam configs to /usr/share/hifam in the installed system
echo "Copying HiFam configuration to /usr/share/hifam..."
mkdir -p "$MOUNT_POINT/usr/share/hifam"
cp -rv "$CONFIG_DIR"/* "$MOUNT_POINT/usr/share/hifam/" || echo "Some files failed to copy"

# Make all scripts in hifam-arch-scripts executable
echo "Making scripts executable..."
if [ -d "$MOUNT_POINT/usr/share/hifam/hifam-arch-scripts" ]; then
    chmod +x "$MOUNT_POINT/usr/share/hifam/hifam-arch-scripts"/*.sh
    echo "✓ Scripts in hifam-arch-scripts are now executable"
fi

# Copy Plymouth theme files if they exist
if [ -d "/usr/share/plymouth/themes/hifam" ]; then
    echo "Copying Plymouth theme..."
    mkdir -p "$MOUNT_POINT/usr/share/plymouth/themes/hifam"
    cp -r /usr/share/plymouth/themes/hifam/* "$MOUNT_POINT/usr/share/plymouth/themes/hifam/" || true
    
    # Activate Plymouth theme in the installed system
    echo "Activating Plymouth theme..."
    arch-chroot "$MOUNT_POINT" plymouth-set-default-theme hifam 2>&1 | grep -v "^$" || echo "  (Plymouth theme set)"
    
    echo "Rebuilding initramfs..."
    arch-chroot "$MOUNT_POINT" mkinitcpio -P 2>&1 | tail -5 || echo "  (Initramfs rebuild complete)"
    
    echo "✓ Plymouth theme activated!"
fi

# Setup user dotfiles automatically
echo ""
echo "Setting up user dotfiles..."

# Find the user (first non-root user with UID >= 1000)
USER_INFO=$(arch-chroot "$MOUNT_POINT" getent passwd {1000..60000} 2>/dev/null | head -n1)

if [ -n "$USER_INFO" ]; then
    USERNAME=$(echo "$USER_INFO" | cut -d: -f1)
    USER_HOME=$(echo "$USER_INFO" | cut -d: -f6)
    
    echo "Found user: $USERNAME ($USER_HOME)"
    
    # Create .config directory (but NOT the subdirectories we'll symlink)
    echo "Creating .config directory..."
    arch-chroot "$MOUNT_POINT" mkdir -p "$USER_HOME/.config/tmux"
    
    # Create symlinks for main configs (these become the directories themselves)
    echo "Creating symlinks..."
    arch-chroot "$MOUNT_POINT" ln -sf /usr/share/hifam/hypr "$USER_HOME/.config/hypr"
    arch-chroot "$MOUNT_POINT" ln -sf /usr/share/hifam/nvim "$USER_HOME/.config/nvim"
    arch-chroot "$MOUNT_POINT" ln -sf /usr/share/hifam/kitty "$USER_HOME/.config/kitty"
    [ -d "$MOUNT_POINT/usr/share/hifam/mouseless" ] && arch-chroot "$MOUNT_POINT" ln -sf /usr/share/hifam/mouseless "$USER_HOME/.config/mouseless"
    
    # Copy tmux config (we created the tmux directory above)
    echo "Copying tmux config..."
    arch-chroot "$MOUNT_POINT" cp /usr/share/hifam/tmux.conf "$USER_HOME/.config/tmux/tmux.conf" 2>/dev/null || true
    
    # Copy shell configs
    echo "Copying shell configs..."
    arch-chroot "$MOUNT_POINT" cp /usr/share/hifam/zshrc "$USER_HOME/.zshrc" 2>/dev/null || true
    arch-chroot "$MOUNT_POINT" cp /usr/share/hifam/p10k.zsh "$USER_HOME/.p10k.zsh" 2>/dev/null || true

        # =========================================================
    # Everything below runs inside the installed system
    # =========================================================

    echo ""
    echo "=== Configuring installed system ==="

    # ---------------------------------------------------------
    # Install and configure mouseless
    # ---------------------------------------------------------

    echo "Setting up mouseless..."

    arch-chroot "$MOUNT_POINT" groupadd --system mouseless 2>/dev/null || true

    arch-chroot "$MOUNT_POINT" usermod \
        -aG input,mouseless "$USERNAME"

    arch-chroot "$MOUNT_POINT" tee \
        /etc/udev/rules.d/99-mouseless-input.rules > /dev/null <<EOF
KERNEL=="uinput", GROUP="mouseless", MODE:="0660"
EOF

    arch-chroot "$MOUNT_POINT" modprobe uinput

    arch-chroot "$MOUNT_POINT" sh -c \
        'echo uinput > /etc/modules-load.d/uinput.conf'

    arch-chroot "$MOUNT_POINT" udevadm control --reload-rules
    arch-chroot "$MOUNT_POINT" udevadm trigger

    echo "Installing Flatpak..."
    arch-chroot "$MOUNT_POINT" pacman -S --needed --noconfirm flatpak

    arch-chroot "$MOUNT_POINT" flatpak remote-add \
    --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

    arch-chroot "$MOUNT_POINT" flatpak install -y \
        flathub org.gnome.Platform//50

    echo "Adding Sonuscape repository..."

    arch-chroot "$MOUNT_POINT" runuser -u "$USERNAME" -- env \
        HOME="$USER_HOME" \
        flatpak remote-add --user --if-not-exists \
        sonuscape \
        https://dl.sonuscape.net/flatpak/sonuscape.flatpakrepo

    echo "Installing mouseless..."

    arch-chroot "$MOUNT_POINT" runuser -u "$USERNAME" -- env \
        HOME="$USER_HOME" \
        flatpak install --user -y \
        sonuscape net.sonuscape.mouseless

    echo "Configuring mouseless..."

    arch-chroot "$MOUNT_POINT" runuser -u "$USERNAME" -- env \
        HOME="$USER_HOME" \
        mkdir -p \
        "$USER_HOME/.var/app/net.sonuscape.mouseless/data/mouseless/configs"

    arch-chroot "$MOUNT_POINT" cp \
        /usr/share/hifam/mouseless/config.yaml \
        "$USER_HOME/.var/app/net.sonuscape.mouseless/data/mouseless/configs/config.yaml"

    arch-chroot "$MOUNT_POINT" chown -R \
        "$USERNAME:$USERNAME" \
        "$USER_HOME/.var/app/net.sonuscape.mouseless"

    echo "✓ Mouseless configured!"

    # ---------------------------------------------------------
    # Build and install wl-kbptr
    # ---------------------------------------------------------

    echo "Setting up wl-kbptr..."

    echo "Installing wl-kbptr build dependencies..."

    arch-chroot "$MOUNT_POINT" pacman -S --needed --noconfirm \
        git \
        meson \
        ninja \
        opencv

    arch-chroot "$MOUNT_POINT" runuser -u "$USERNAME" -- env \
        HOME="$USER_HOME" \
        bash -c '
            rm -rf "$HOME/wl-kbptr"

            git clone \
                https://github.com/DereckAn/wl-kbptr.git \
                "$HOME/wl-kbptr"

            cd "$HOME/wl-kbptr"

            git checkout fix/opencv5

            meson setup build \
                --buildtype=release \
                -Dopencv=enabled

            meson compile -C build
        '

    arch-chroot "$MOUNT_POINT" cp \
        "$USER_HOME/wl-kbptr/build/wl-kbptr" \
        /usr/bin/wl-kbptr

    arch-chroot "$MOUNT_POINT" chown -R \
        "$USERNAME:$USERNAME" \
        "$USER_HOME/wl-kbptr"

    echo "✓ wl-kbptr installed!"

    # ---------------------------------------------------------
    # Install Oh My Zsh
    # ---------------------------------------------------------

    echo "Installing Oh My Zsh..."

    arch-chroot "$MOUNT_POINT" runuser -u "$USERNAME" -- env \
        HOME="$USER_HOME" \
        USER="$USERNAME" \
        LOGNAME="$USERNAME" \
        zsh -c '
            RUNZSH=no CHSH=no \
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        '

    # ---------------------------------------------------------
    # Install Powerlevel10k
    # ---------------------------------------------------------

    echo "Installing Powerlevel10k..."

    arch-chroot "$MOUNT_POINT" runuser -u "$USERNAME" -- env \
        HOME="$USER_HOME" \
        git clone --depth=1 \
        https://github.com/romkatv/powerlevel10k.git \
        "$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"

    # ---------------------------------------------------------
    # Install zsh-autosuggestions
    # ---------------------------------------------------------

    echo "Installing zsh plugins..."

    arch-chroot "$MOUNT_POINT" runuser -u "$USERNAME" -- env \
        HOME="$USER_HOME" \
        git clone \
        https://github.com/zsh-users/zsh-autosuggestions \
        "$USER_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

    # ---------------------------------------------------------
    # Install yay
    # ---------------------------------------------------------
    #
    echo "Installing sudo..."

    arch-chroot "$MOUNT_POINT" pacman -S --needed --noconfirm sudo

    echo "Configuring sudo for $USERNAME..."

    arch-chroot "$MOUNT_POINT" bash -c \
        "echo '$USERNAME ALL=(ALL:ALL) ALL' > /etc/sudoers.d/$USERNAME"

    arch-chroot "$MOUNT_POINT" chmod 440 \
        "/etc/sudoers.d/$USERNAME"

    arch-chroot "$MOUNT_POINT" visudo -c


    echo "Installing yay for $USERNAME..."

    arch-chroot "$MOUNT_POINT" pacman -S --needed --noconfirm \
        base-devel git

    arch-chroot "$MOUNT_POINT" runuser -u "$USERNAME" -- env \
        HOME="$USER_HOME" \
        USER="$USERNAME" \
        LOGNAME="$USERNAME" \
        bash -c '
            cd /tmp

            rm -rf yay

            git clone \
                https://aur.archlinux.org/yay.git

            cd yay

            makepkg -si --noconfirm

            cd /

            rm -rf /tmp/yay
        '

    echo "✓ yay installed!"

    # ---------------------------------------------------------
    # Set zsh as default shell
    # ---------------------------------------------------------

    echo "Setting zsh as default shell..."

    arch-chroot "$MOUNT_POINT" chsh \
        -s /usr/bin/zsh \
        "$USERNAME"

    # ---------------------------------------------------------
    # Final ownership
    # ---------------------------------------------------------

    echo "Fixing user ownership..."

    arch-chroot "$MOUNT_POINT" chown -R \
        "$USERNAME:$USERNAME" \
        "$USER_HOME"

    arch-chroot "$MOUNT_POINT" chown -R \
        "$USERNAME:$USERNAME" \
        /usr/share/hifam

    arch-chroot "$MOUNT_POINT" chmod -R \
        u+rwX \
        /usr/share/hifam

    echo "✓ User environment configured!"
    
    echo "✓ Dotfiles configured for $USERNAME!"
else
    echo "⚠ No user found (UID >= 1000)"
    echo "  Dotfiles copied to /usr/share/hifam for manual setup"
fi

# Setup keyd
echo ""
echo "Setting up keyd..."
if [ -f "$MOUNT_POINT/usr/share/hifam/keyd/default.conf" ]; then
    mkdir -p "$MOUNT_POINT/etc/keyd"
    cp "$MOUNT_POINT/usr/share/hifam/keyd/default.conf" "$MOUNT_POINT/etc/keyd/"
    arch-chroot "$MOUNT_POINT" systemctl enable keyd 2>/dev/null && echo "✓ keyd enabled" || echo "  (keyd will be enabled on first boot)"
fi

# Configure GRUB to say "HiFam Arch"
echo ""
echo "Configuring GRUB bootloader..."
if [ -f "$MOUNT_POINT/etc/default/grub" ]; then
    # Update GRUB_DISTRIBUTOR to HiFam Arch
    sed -i 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="HiFam Arch"/' "$MOUNT_POINT/etc/default/grub"
    
    # Regenerate GRUB config
    echo "Regenerating GRUB configuration..."
    arch-chroot "$MOUNT_POINT" grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | grep -E "Found|Generating" || echo "  (GRUB config regenerated)"
    echo "✓ GRUB configured to show 'HiFam Arch'"
fi

# Create a simple README for the user
cat > "$MOUNT_POINT/usr/share/hifam/README.txt" << 'EOFREADME'
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║  HiFam Arch Configuration Files                                  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Your HiFam dotfiles and configuration scripts are here!

LOCATION: /usr/share/hifam/

CONTENTS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• hifam-arch-scripts/  - Post-installation scripts
• nvim/                - Neovim configuration
• kitty/               - Kitty terminal config
• hypr/                - Hyprland configuration
• keyd/                - Keyboard remapping
• tmux.conf            - Tmux configuration
• zshrc                - Zsh shell config
• p10k.zsh             - Powerlevel10k theme
• user_configuration.json - Archinstall config reference

MANUAL SETUP:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Copy configs to your home:
   cp -r /usr/share/hifam ~/hifam-config

2. Run individual setup scripts:
   cd ~/hifam-config/hifam-arch-scripts
   ./2-install-packages.sh  (install packages)
   ./6-setup-symlinks.sh    (create dotfile symlinks)
   ./8-zsh-setup.sh         (setup zsh)
   etc...

3. Or manually create symlinks:
   ln -sf /usr/share/hifam/nvim ~/.config/nvim
   ln -sf /usr/share/hifam/kitty ~/.config/kitty
   ln -sf /usr/share/hifam/hypr ~/.config/hypr
   cp /usr/share/hifam/zshrc ~/.zshrc
   cp /usr/share/hifam/p10k.zsh ~/.p10k.zsh
   cp /usr/share/hifam/tmux.conf ~/.config/tmux/

4. Setup keyd (keyboard remapping):
   sudo cp /usr/share/hifam/keyd/default.conf /etc/keyd/
   sudo systemctl enable keyd
   sudo systemctl start keyd

5. Setup Plymouth (boot splash):
   sudo plymouth-set-default-theme hifam
   sudo mkinitcpio -P

QUICK START:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Copy everything to your home
cp -r /usr/share/hifam ~/hifam-config

# Create symlinks for main configs
mkdir -p ~/.config
ln -sf ~/hifam-config/nvim ~/.config/nvim
ln -sf ~/hifam-config/kitty ~/.config/kitty
ln -sf ~/hifam-config/hypr ~/.config/hypr

# Copy shell configs
cp ~/hifam-config/zshrc ~/.zshrc
cp ~/hifam-config/p10k.zsh ~/.p10k.zsh

# Setup keyd
sudo cp ~/hifam-config/keyd/default.conf /etc/keyd/
sudo systemctl enable --now keyd

# Setup Plymouth
sudo plymouth-set-default-theme hifam
sudo mkinitcpio -P

Done! Logout and login to see changes.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For more info: https://github.com/MontyTheSoftwareEngineer/hifam-arch
EOFREADME

echo ""
echo "╔════════════════════════════════════════╗"
echo "║  ✅ Installation Complete!             ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Your configs are installed at: /usr/share/hifam"
echo ""
echo "Next steps:"
echo "  1. umount -R $MOUNT_POINT"
echo "  2. reboot"
echo ""
echo "After booting into your new system:"
echo "  • Your configs are in /usr/share/hifam"
echo "  • Read /usr/share/hifam/README.txt for setup instructions"
echo "  • Run scripts manually or copy configs as needed"
echo ""

exit 0
