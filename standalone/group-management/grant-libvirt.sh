#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

usage() {
    echo "Usage: $0 [username]"
}

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

USER_NAME="${1:-${SUDO_USER:-}}"

if [[ -z "$USER_NAME" ]]; then
    usage
    exit 1
fi

USERNAME="$USER_NAME"

echo "==> Grant libvirt access"

if ! getent group libvirt >/dev/null 2>&1; then
    echo "libvirt group does not exist."
    echo "Install the QEMU/KVM stack first."
    exit 1
fi

if ! id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' does not exist."
    exit 1
fi

if getent group libvirt | grep -qw "$USERNAME"; then
    echo "User '$USERNAME' is already a member of the libvirt group."
    exit 0
fi

echo "Adding '$USERNAME' to libvirt group..."
usermod -aG libvirt "$USERNAME"

echo ""
echo "User '$USERNAME' added to the libvirt group."
echo "The user must log out and log back in for the new group membership to take effect."
