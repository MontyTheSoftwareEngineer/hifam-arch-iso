# HiFam Arch Linux Custom ISO

This is a custom Arch Linux ISO with pre-configured settings and dotfiles.

## What's Included

- **archinstall configurations**: Pre-configured JSON files for automated installation
- **Dotfiles**: nvim, kitty, hypr, keyd, tmux, zsh configurations
- **Post-installation scripts**: Automated setup after installation
- **Custom packages**: Your preferred package selection

## Quick Start

1. Boot from this ISO
2. Login as `root` (no password)
3. Run the installer:
   ```bash
   ./install-hifam.sh
   ```

## Manual Installation

If you prefer manual installation:

1. Run archinstall with the included config:
   ```bash
   archinstall --config /root/hifam-config/user_configuration.json \
               --creds /root/hifam-config/user_credentials.json
   ```

2. After installation, run post-install setup:
   ```bash
   arch-chroot /mnt /root/post-install.sh
   ```

## What Happens During Post-Installation

The post-install script will:
- Copy all HiFam configurations to your new system
- Set up keyd for keyboard customization
- Install additional packages from your list
- Configure dotfiles (nvim, kitty, hypr, tmux, zsh)
- Create symlinks to your dotfiles
- Run your custom setup scripts

## Configuration Files Location

In the ISO:
- `/root/hifam-config/` - All your dotfiles and configs
- `/root/install-hifam.sh` - Main installer script
- `/root/post-install.sh` - Post-installation script

After installation:
- `/root/hifam-config/` - Configuration files (in the new system)
- Logs in `/var/log/hifam-*.log`

## Customization

All your configuration files are in `/root/hifam-config/`:
- `user_configuration.json` - archinstall config
- `user_credentials.json` - user credentials
- `hifam-arch-scripts/` - Post-install scripts
- `keyd/`, `nvim/`, `kitty/`, `hypr/` - Dotfiles directories
- Various other dotfiles (zshrc, tmux.conf, p10k.zsh)

## Building This ISO

To rebuild this ISO:
```bash
cd ~/hifam-arch
sudo mkarchiso -v -w work/ -o out/ .
```

## Troubleshooting

- Check logs in `/var/log/hifam-*.log` after installation
- Configuration backup files are created in `~/.config/*.backup`
- Original configs are preserved before symlinking

## Source

GitHub: https://github.com/MontyTheSoftwareEngineer/hifam-arch
