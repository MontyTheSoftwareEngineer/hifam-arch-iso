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
3. The ISO will show `/root/hifam.txt` and launch `./install-hifam.sh` automatically on TTY1
4. Follow the prompts for disk layout, hostname, username, and password

## Manual Installation

If you prefer manual installation:

1. Run the interactive Arch install helper:
   ```bash
   ./arch-install.sh
   ```

2. After installation, run post-install setup:
   ```bash
   ./post-install.sh
   ```

## What Happens During Post-Installation

The post-install script will:
- Copy all HiFam configurations to your new system
- Restore executable permissions on copied shell scripts
- Set up keyd for keyboard customization
- Configure dotfiles (nvim, kitty, hypr, tmux, zsh)
- Run dedicated chroot helper scripts for sudo, fonts, mouseless, wl-kbptr, zsh, and system tweaks

## Configuration Files Location

In the ISO:
- `/root/hifam-config/` - All your dotfiles and configs
- `/root/install-hifam.sh` - Main installer script
- `/root/arch-install.sh` - Interactive archinstall wrapper
- `/root/post-install.sh` - Post-installation script
- `/root/postinstall/` - Chroot helper scripts copied into the new install

After installation:
- `/usr/share/hifam/` - Configuration files in the new system
- `/root/hifam-postinstall/` - Copied post-install helper scripts

## Customization

All your configuration files are in `/root/hifam-config/`:
- `user_configuration.json` - archinstall config
- `user_credentials.json` - legacy placeholder; the live installer now prompts for credentials
- `hifam-arch-scripts/` - Post-install scripts
- `tmux/tmux.conf` - Tmux configuration
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
