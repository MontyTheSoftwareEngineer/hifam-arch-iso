#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
ensure_target_user

pacman -S --needed --noconfirm sudo base-devel git

printf '%s ALL=(ALL:ALL) ALL\n' "$USERNAME" > "/etc/sudoers.d/$USERNAME"
chmod 0440 "/etc/sudoers.d/$USERNAME"
visudo -cf "/etc/sudoers.d/$USERNAME"
