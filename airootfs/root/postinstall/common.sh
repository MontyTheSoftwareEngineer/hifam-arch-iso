#!/bin/bash

CONFIG_DIR="${HIFAM_CONFIG_DIR:-/usr/share/hifam}"

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
    runuser -u "$USERNAME" -- env \
        HOME="$USER_HOME" \
        USER="$USERNAME" \
        LOGNAME="$USERNAME" \
        "$@"
}

backup_user_config_dir() {
    local name="$1"
    local path="$USER_HOME/.config/$name"

    if [ -d "$path" ] && [ ! -L "$path" ]; then
        mv "$path" "$path.bak"
    fi
}
