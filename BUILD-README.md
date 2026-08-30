# HiFam Arch ISO Profile

Custom Arch Linux ISO with pre-configured dotfiles and automated installation.

## Directory Structure

```
~/hifam-arch/
├── airootfs/
│   ├── root/
│   │   ├── hifam-config/          # Your dotfiles and configs
│   │   │   ├── user_configuration.json
│   │   │   ├── user_credentials.json
│   │   │   ├── hifam-arch-scripts/
│   │   │   ├── keyd/
│   │   │   ├── nvim/
│   │   │   ├── kitty/
│   │   │   ├── hypr/
│   │   │   ├── tmux.conf
│   │   │   ├── zshrc
│   │   │   └── ...
│   │   ├── install-hifam.sh      # Main installer (runs archinstall + post-install)
│   │   ├── post-install.sh       # Post-installation setup (runs in chroot)
│   │   └── README.md
│   └── etc/
│       └── motd                   # Custom welcome message
├── packages.x86_64                # Packages to include in ISO
├── profiledef.sh                  # ISO build configuration
├── build-iso.sh                   # Build script (run this)
└── README.md                      # This file
```

## What's Included

### Live ISO Features
- Full Arch Linux live environment
- archinstall with pre-configured settings
- All your dotfiles embedded in the ISO
- Automated post-installation setup

### Included Configurations
- **archinstall JSON configs**: Automated installation with Hyprland, SDDM, etc.
- **Dotfiles**: nvim, kitty, hypr, keyd, tmux, zsh configurations
- **Scripts**: Post-installation automation scripts
- **System configs**: keyd for keyboard remapping

### Post-Installation Automation
The `post-install.sh` script (runs in chroot after archinstall):
1. Copies all configs to the new system
2. Sets up keyd systemd service
3. Installs packages from your script
4. Configures dotfiles and creates symlinks
5. Sets up zsh, tmux, and other tools

## Building the ISO

### Prerequisites
```bash
sudo pacman -S archiso
```

### Build
```bash
cd ~/hifam-arch
./build-iso.sh
```

The script will:
- Verify the profile structure
- Clean previous builds (optional)
- Build the ISO (requires sudo)
- Output ISO to `~/hifam-arch-iso-output/`

Build time: ~10-20 minutes depending on your system.

### Manual Build
```bash
sudo mkarchiso -v -w ~/hifam-arch-work -o ~/hifam-arch-iso-output ~/hifam-arch
```

## Using the ISO

### 1. Write to USB
```bash
# Find your USB device
lsblk

# Write ISO (replace sdX with your device)
sudo dd if=~/hifam-arch-iso-output/hifam-arch-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

### 2. Boot from USB
- Boot your computer from the USB drive
- Login as `root` (no password)

### 3. Install
```bash
# Automated installation (recommended)
./install-hifam.sh

# Or manual
archinstall --config /root/hifam-config/user_configuration.json \
            --creds /root/hifam-config/user_credentials.json
```

### 4. Post-Installation
The installer automatically runs post-installation setup in chroot.
If you need to run it manually:
```bash
arch-chroot /mnt /root/post-install.sh
```

## Testing in VM

Test before writing to USB:
```bash
# Using QEMU
qemu-system-x86_64 -enable-kvm -m 4G -boot d \
    -cdrom ~/hifam-arch-iso-output/hifam-arch-*.iso

# Using VirtualBox
# Create new VM, attach ISO, boot
```

## Customization

### Update Configurations
1. Edit files in `/home/hpham/hifam-arch-files/`
2. Sync to ISO profile:
   ```bash
   cd /home/hpham/hifam-arch-files
   cp -r keyd hypr kitty mouseless nvim scripts sunset-theme \
         ~/hifam-arch/airootfs/root/hifam-config/
   cp user_configuration.json user_credentials.json p10k.zsh \
      tmux.conf zshrc ~/hifam-arch/airootfs/root/hifam-config/
   ```
3. Rebuild ISO: `./build-iso.sh`

### Add Packages to ISO
Edit `~/hifam-arch/packages.x86_64` and add package names (one per line).

### Modify Scripts
- Edit `~/hifam-arch/airootfs/root/install-hifam.sh` - main installer
- Edit `~/hifam-arch/airootfs/root/post-install.sh` - post-install automation
- Edit scripts in `~/hifam-arch/airootfs/root/hifam-config/hifam-arch-scripts/`

## Troubleshooting

### Build Issues
- **Permission denied**: Make sure to run with sudo: `sudo mkarchiso ...`
- **Missing packages**: Install archiso: `sudo pacman -S archiso`
- **Disk space**: ISO build needs ~3-5GB free space

### Installation Issues
- Check logs in `/var/log/hifam-*.log` (after installation)
- Verify files exist: `ls -la /root/hifam-config/`
- Test in VM first before installing on real hardware

### Post-Install Issues
- Scripts create backups: `~/.config/*/*.backup`
- Logs: `/var/log/hifam-*.log`
- Manual run: `arch-chroot /mnt /root/post-install.sh`

## Files Reference

### In the ISO (Live Environment)
- `/root/hifam-config/` - All your configs
- `/root/install-hifam.sh` - Main installer
- `/root/post-install.sh` - Post-install script
- `/root/README.md` - Quick reference

### After Installation (Installed System)
- `/root/hifam-config/` - Config backup
- `~/.config/nvim/` -> symlink to `/root/hifam-config/nvim`
- `~/.config/kitty/` -> symlink to `/root/hifam-config/kitty`
- `~/.config/hypr/` -> symlink to `/root/hifam-config/hypr`
- `/var/log/hifam-*.log` - Installation logs

## GitHub Repository

Source: https://github.com/MontyTheSoftwareEngineer/hifam-arch

Keep your configs in sync:
```bash
cd /home/hpham/hifam-arch-files
git pull
# Copy updated files to ISO profile
# Rebuild ISO
```

## License

Based on the official Arch Linux archiso profile.
Your configurations: as per your preference.
