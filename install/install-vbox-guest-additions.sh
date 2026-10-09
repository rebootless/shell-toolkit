#!/bin/bash

# ---DOC-START---
# summary: Install VirtualBox Guest Additions from the mounted ISO.
# description: |
#   Installs [VirtualBox Guest Additions](https://www.virtualbox.org/manual/ch04.html)
#   by running the vendor installer from the mounted Guest Additions ISO.
#
#   - **Run this inside the guest VM**, not on the host.
#   - **Before running**: mount the Guest Additions ISO first. In the VirtualBox VM window, use `Devices -> Insert Guest Additions CD image...` (or attach `VBoxGuestAdditions.iso` manually), then re-run this script.
#   - Installs `dkms`, `build-essential`, and a matching kernel headers package via apt, then runs the vendor installer from the mounted image.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script." >&2
    exit 1
fi

pkg_exists() {
    apt-cache show "$1" >/dev/null 2>&1
}

detect_headers_pkg() {
    if pkg_exists "linux-headers-$(uname -r)"; then
        echo "linux-headers-$(uname -r)"
        return 0
    fi

    if pkg_exists linux-headers-generic; then
        echo "linux-headers-generic"
        return 0
    fi

    if pkg_exists linux-headers-amd64; then
        echo "linux-headers-amd64"
        return 0
    fi

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

echo "Updating package lists..."
apt-get update

echo "Installing prerequisites..."
apt-get install -y dkms build-essential

HEADERS_PKG="$(detect_headers_pkg)" || {
    echo "Could not determine a suitable kernel headers package." >&2
    exit 1
}

echo "Installing kernel headers: ${HEADERS_PKG}"
apt-get install -y "$HEADERS_PKG"

INSTALLER="$(find_vbox_ga_installer)" || {
    echo "Guest Additions ISO is not mounted."
    echo "In VirtualBox, use: Devices -> Insert Guest Additions CD image..."
    echo "Then re-run this script."
    exit 1
}

echo "Found Guest Additions installer: ${INSTALLER}"
echo "Running Guest Additions installer..."

INSTALL_EXIT=0
sh "$INSTALLER" || INSTALL_EXIT=$?

if (( INSTALL_EXIT != 0 )); then
    echo "Installer returned exit code ${INSTALL_EXIT}, verifying kernel modules..."
fi

echo "Loading modules..."
modprobe vboxguest 2>/dev/null || true
modprobe vboxsf 2>/dev/null || true
modprobe vboxvideo 2>/dev/null || true

if ! lsmod | grep -q '^vboxguest'; then
    echo "vboxguest module is not loaded. Guest Additions installation appears to have failed." >&2
    exit 1
fi

echo "VirtualBox Guest Additions installation completed successfully."
if (( INSTALL_EXIT != 0 )); then
    echo "Note: the installer returned a non-zero exit code, but the kernel modules are loaded."
fi

echo ""
echo "Reboot the guest system to finish activation."
echo ""
echo "Loaded VirtualBox modules:"
lsmod | grep vbox || echo "No VirtualBox modules are currently loaded."

echo ""
echo "vboxadd service status:"
if systemctl list-unit-files | grep -q '^vboxadd'; then
    systemctl status vboxadd --no-pager || true
else
    echo "vboxadd service is not present."
fi
