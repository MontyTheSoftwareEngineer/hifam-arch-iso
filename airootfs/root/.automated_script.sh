#!/usr/bin/env bash

brand_os_release() {
    local os_release_file=/etc/os-release

    if [[ -L "${os_release_file}" ]]; then
        local resolved_file
        resolved_file="$(readlink -f "${os_release_file}")"
        if [[ -n "${resolved_file}" && -f "${resolved_file}" ]]; then
            os_release_file="${resolved_file}"
        fi
    fi

    [[ -f "${os_release_file}" ]] || return 0

    if grep -q '^NAME="HiFam Arch OS"$' "${os_release_file}" &&
       grep -q '^PRETTY_NAME="HiFam Arch OS"$' "${os_release_file}"; then
        return 0
    fi

    sed -i \
        -e 's|^NAME=.*|NAME="HiFam Arch OS"|' \
        -e 's|^PRETTY_NAME=.*|PRETTY_NAME="HiFam Arch OS"|' \
        -e 's|^HOME_URL=.*|HOME_URL="https://github.com/MontyTheSoftwareEngineer/hifam-arch"|' \
        -e 's|^SUPPORT_URL=.*|SUPPORT_URL="https://github.com/MontyTheSoftwareEngineer/hifam-arch/issues"|' \
        -e 's|^BUG_REPORT_URL=.*|BUG_REPORT_URL="https://github.com/MontyTheSoftwareEngineer/hifam-arch/issues"|' \
        "${os_release_file}"
}

script_cmdline() {
    local param
    for param in $(</proc/cmdline); do
        case "${param}" in
            script=*)
                echo "${param#*=}"
                return 0
                ;;
        esac
    done
}

automated_script() {
    local script rt
    brand_os_release
    script="$(script_cmdline)"
    if [[ -n "${script}" && ! -x /tmp/startup_script ]]; then
        if [[ "${script}" =~ ^((http|https|ftp|tftp)://) ]]; then
            printf '%s: downloading %s\n' "$0" "${script}"
            # there's no synchronization for network availability before executing this script; to ensure the network
            # is online, we use a transient systemd service that depends on network-online.target to download the
            # script rather than manually polling the target
            systemd-run --pty --quiet -p Wants=network-online.target -p After=network-online.target \
                curl "${script}" --location --retry-connrefused --retry 10 --fail -s -o /tmp/startup_script
            rt=$?
        else
            cp "${script}" /tmp/startup_script
            rt=$?
        fi
        if [[ ${rt} -eq 0 ]]; then
            chmod +x /tmp/startup_script
            printf '%s: executing automated script\n' "$0"
            # note that script is executed when other services (like pacman-init) may be still in progress, please
            # synchronize to "systemctl is-system-running --wait" when your script depends on other services
            /tmp/startup_script
        fi
    elif [[ -x /root/install-hifam.sh && ! -e /tmp/hifam-installer-started ]]; then
        touch /tmp/hifam-installer-started
        clear
        if [[ -r /root/hifam.txt ]]; then
            cat /root/hifam.txt
            printf '\n'
        fi
        /root/install-hifam.sh
    fi
}

if [[ $(tty) == "/dev/tty1" ]]; then
    automated_script
fi
