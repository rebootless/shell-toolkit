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

GUEST_PKGS=()

if pkg_exists virtualbox-guest-dkms; then
    GUEST_PKGS+=("virtualbox-guest-dkms")
fi

if pkg_exists virtualbox-guest-utils; then
    GUEST_PKGS+=("virtualbox-guest-utils")
fi

if pkg_exists virtualbox-guest-x11; then
    GUEST_PKGS+=("virtualbox-guest-x11")
fi

if pkg_exists virtualbox-guest-additions-iso; then
    GUEST_PKGS+=("virtualbox-guest-additions-iso")
fi

if [[ ${#GUEST_PKGS[@]} -eq 0 ]]; then
    echo "[!] No VirtualBox guest packages were found in the configured repositories."
    echo "[!] You can still use the Guest Additions ISO from the VirtualBox menu if needed."
else
    log "Installing VirtualBox guest packages..."
    apt-get install -y "${GUEST_PKGS[@]}"
fi

log "Loading guest modules..."
modprobe vboxguest 2>/dev/null || true
modprobe vboxsf 2>/dev/null || true
modprobe vboxvideo 2>/dev/null || true

log "Verifying installation..."
if ! lsmod | grep -q '^vboxguest'; then
    echo "[!] vboxguest module is not loaded."
    exit 1
fi

echo "[+] VirtualBox Guest Additions installation completed successfully."
echo "[i] Reboot the guest system to finish activation."
