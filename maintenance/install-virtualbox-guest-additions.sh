#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then
    echo "[!] Cannot detect distribution."
    exit 1
fi

. /etc/os-release

case "${ID:-}" in
    debian|ubuntu|linuxmint|pop|kali)
        ;;
    *)
        echo "[!] This script is intended for Debian/Ubuntu-based guests."
        exit 1
        ;;
esac

log() {
    echo "[*] $*"
}

pkg_exists() {
    apt-cache show "$1" >/dev/null 2>&1
}

detect_headers_pkg() {
    if pkg_exists "linux-headers-$(uname -r)"; then
        echo "linux-headers-$(uname -r)"
        return 0
    fi

    case "${ID:-}" in
        debian|linuxmint|kali)
            if pkg_exists linux-headers-amd64; then
                echo "linux-headers-amd64"
                return 0
            fi
            ;;
        ubuntu|pop)
            if pkg_exists linux-headers-generic; then
                echo "linux-headers-generic"
                return 0
            fi
            ;;
    esac

    return 1
}

find_vbox_ga_installer() {
    local candidates=(
        "/media/cdrom/VBoxLinuxAdditions.run"
        "/media/cdrom0/VBoxLinuxAdditions.run"
        "/run/media/${SUDO_USER:-root}/VBox_GAs_"*/VBoxLinuxAdditions.run
        "/mnt/VBoxLinuxAdditions.run"
    )

    local path
    for path in "${candidates[@]}"; do
        for path in $path; do
            if [[ -f "$path" ]]; then
                echo "$path"
                return 0
            fi
        done
    done

    return 1
}

log "Updating package lists..."
apt-get update

log "Installing prerequisites..."
apt-get install -y dkms build-essential

HEADERS_PKG="$(detect_headers_pkg)" || {
    echo "[!] Could not determine a suitable kernel headers package."
    exit 1
}

log "Installing kernel headers: ${HEADERS_PKG}"
apt-get install -y "$HEADERS_PKG"

if INSTALLER="$(find_vbox_ga_installer)"; then
    log "Found Guest Additions installer: ${INSTALLER}"
else
    echo "[!] Guest Additions ISO is not mounted."
    echo "[!] In VirtualBox, use: Devices -> Insert Guest Additions CD image..."
    echo "[!] Then re-run this script."
    exit 1
fi

log "Running Guest Additions installer..."

INSTALL_EXIT=0
sh "$INSTALLER" || INSTALL_EXIT=$?

if (( INSTALL_EXIT != 0 )); then
    echo "[!] Guest Additions installer returned exit code ${INSTALL_EXIT}."
    echo "[!] Verifying whether the kernel modules were installed..."
fi

log "Attempting to load modules..."
modprobe vboxguest 2>/dev/null || true
modprobe vboxsf 2>/dev/null || true
modprobe vboxvideo 2>/dev/null || true

if lsmod | grep -q '^vboxguest'; then
    echo "[+] VirtualBox Guest Additions installation completed successfully."

    if (( INSTALL_EXIT != 0 )); then
        echo "[i] The installer returned a non-zero exit code, but the kernel modules are loaded."
    fi

    echo "[i] Reboot the guest system to finish activation."

    echo
    echo "[i] Loaded VirtualBox modules:"
    if ! lsmod | grep vbox; then
        echo "[i] No VirtualBox modules are currently loaded."
    fi

    echo
    echo "[i] vboxadd service status:"
    if systemctl list-unit-files | grep -q '^vboxadd'; then
        systemctl status vboxadd --no-pager || true
    else
        echo "[i] vboxadd service is not present."
    fi
else
    echo "[!] vboxguest module is not loaded."
    echo "[!] Guest Additions installation appears to have failed."
    exit 1
fi
