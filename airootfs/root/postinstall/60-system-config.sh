#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_os_release_branding() {
    install -d /usr/local/lib/hifam /etc/pacman.d/hooks

    cat > /usr/local/lib/hifam/refresh-os-release-branding <<'EOFBRAND'
#!/bin/bash

set -euo pipefail

OS_RELEASE_FILE="/etc/os-release"

if [ -L "$OS_RELEASE_FILE" ]; then
    resolved_file="$(readlink -f "$OS_RELEASE_FILE")"
    if [ -n "$resolved_file" ] && [ -f "$resolved_file" ]; then
        OS_RELEASE_FILE="$resolved_file"
    fi
fi

if [ ! -f "$OS_RELEASE_FILE" ]; then
    echo "ERROR: Could not find an os-release file to update." >&2
    exit 1
fi

upsert_field() {
    local key="$1"
    local value="$2"

    if grep -q "^${key}=" "$OS_RELEASE_FILE"; then
        sed -i "s|^${key}=.*|${key}=\"${value}\"|" "$OS_RELEASE_FILE"
    else
        printf '%s="%s"\n' "$key" "$value" >> "$OS_RELEASE_FILE"
    fi
}

upsert_field NAME "HiFam Arch OS"
upsert_field PRETTY_NAME "HiFam Arch OS"
upsert_field HOME_URL "https://github.com/MontyTheSoftwareEngineer/hifam-arch"
upsert_field SUPPORT_URL "https://github.com/MontyTheSoftwareEngineer/hifam-arch/issues"
upsert_field BUG_REPORT_URL "https://github.com/MontyTheSoftwareEngineer/hifam-arch/issues"
EOFBRAND

    chmod 0755 /usr/local/lib/hifam/refresh-os-release-branding

    cat > /etc/pacman.d/hooks/hifam-os-release-branding.hook <<'EOFHOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = archlinux-release

[Action]
Description = Refreshing HiFam Arch OS branding
When = PostTransaction
Exec = /usr/local/lib/hifam/refresh-os-release-branding
EOFHOOK

    /usr/local/lib/hifam/refresh-os-release-branding
}

install_default_editor_config() {
    install -d /etc/profile.d /usr/local/bin

    cat > /etc/profile.d/hifam-editor.sh <<'EOFEDITOR'
export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim"
EOFEDITOR

    chmod 0644 /etc/profile.d/hifam-editor.sh
    ln -sfn /usr/bin/nvim /usr/local/bin/editor
}

install_lid_switch_config() {
    # Let Hyprland's own lid-switch binding (lock, then suspend) handle the
    # lid switch. If logind also acts on it, it can suspend before the lock
    # screen finishes rendering, so the desktop briefly flashes on wake.
    install -d /etc/systemd/logind.conf.d

    cat > /etc/systemd/logind.conf.d/hifam-lid-switch.conf <<'EOFLID'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOFLID

    chmod 0644 /etc/systemd/logind.conf.d/hifam-lid-switch.conf
}

install_os_release_branding
install_default_editor_config
install_lid_switch_config

if [ -f "$CONFIG_DIR/keyd/default.conf" ]; then
    install -d /etc/keyd
    install -m 0644 "$CONFIG_DIR/keyd/default.conf" /etc/keyd/default.conf
    if [ -f /usr/lib/systemd/system/keyd.service ]; then
        systemctl enable keyd
    fi
fi

if [ -f /etc/default/grub ]; then
    if grep -q '^GRUB_DISTRIBUTOR=' /etc/default/grub; then
        sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="HiFam Arch"/' /etc/default/grub
    else
        printf '\nGRUB_DISTRIBUTOR="HiFam Arch"\n' >> /etc/default/grub
    fi

    if command -v grub-mkconfig >/dev/null 2>&1; then
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi

if [ -d /usr/share/plymouth/themes/hifam ] && command -v plymouth-set-default-theme >/dev/null 2>&1; then
    plymouth-set-default-theme hifam
    mkinitcpio -P
fi
