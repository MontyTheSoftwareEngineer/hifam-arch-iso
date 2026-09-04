#!/bin/bash

CONFIG_DIR="${HIFAM_CONFIG_DIR:-/usr/share/hifam}"
DEFAULT_XDG_DATA_DIRS="/usr/local/share:/usr/share:/var/lib/flatpak/exports/share"

ensure_target_user() {
    if [ -n "${USERNAME:-}" ] && [ -n "${USER_HOME:-}" ]; then
        return 0
    fi

    local user_info detected_user creds_user

    user_info="$(
        getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 { print; exit }'
    )"
    if [ -n "$user_info" ]; then
        USERNAME="${user_info%%:*}"
        USER_HOME="$(printf '%s\n' "$user_info" | cut -d: -f6)"
        export USERNAME USER_HOME
        return 0
    fi

    if [ -f "$CONFIG_DIR/user_credentials.json" ]; then
        creds_user="$(
            sed -n 's/.*"username"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
                "$CONFIG_DIR/user_credentials.json" | head -n 1
        )"

        if [ -n "$creds_user" ]; then
            detected_user="$(getent passwd "$creds_user" || true)"
            if [ -n "$detected_user" ]; then
                USERNAME="$creds_user"
                USER_HOME="$(printf '%s\n' "$detected_user" | cut -d: -f6)"
                export USERNAME USER_HOME
                return 0
            fi
        fi
    fi

    echo "ERROR: Could not determine the installed user."
    exit 1
}

run_as_user() {
    ensure_target_user
    runuser -u "$USERNAME" -- env -i \
        HOME="$USER_HOME" \
        USER="$USERNAME" \
        LOGNAME="$USERNAME" \
        SHELL="${SHELL:-/bin/bash}" \
        PATH="/usr/local/sbin:/usr/local/bin:/usr/bin" \
        LANG="${LANG:-en_US.UTF-8}" \
        TERM="${TERM:-xterm-256color}" \
        XDG_CONFIG_HOME="$USER_HOME/.config" \
        XDG_CACHE_HOME="$USER_HOME/.cache" \
        XDG_DATA_HOME="$USER_HOME/.local/share" \
        XDG_STATE_HOME="$USER_HOME/.local/state" \
        XDG_DATA_DIRS="${XDG_DATA_DIRS:-$DEFAULT_XDG_DATA_DIRS}" \
        "$@"
}

backup_user_config_dir() {
    local name="$1"
    local path="$USER_HOME/.config/$name"

    if [ -d "$path" ] && [ ! -L "$path" ]; then
        mv "$path" "$path.bak"
    fi
}

yay_temp_sudoers_file() {
    ensure_target_user
    printf '/etc/sudoers.d/90-hifam-yay-%s\n' "$USERNAME"
}

install_temp_pacman_nopasswd() {
    local sudoers_file

    sudoers_file="$(yay_temp_sudoers_file)"
    printf '%s ALL=(ALL:ALL) NOPASSWD: /usr/bin/pacman\n' "$USERNAME" > "$sudoers_file"
    chmod 0440 "$sudoers_file"
    visudo -cf "$sudoers_file"
}

remove_temp_pacman_nopasswd() {
    rm -f "$(yay_temp_sudoers_file)"
}
