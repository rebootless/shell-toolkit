#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Grant KVM access"

if ! getent group kvm >/dev/null 2>&1; then
    echo "[!] kvm group does not exist."
    echo "    Install the QEMU/KVM stack first."
    exit 1
fi

USERNAME=""

if read -r -t 0; then
    read -r USERNAME
else
    read -rp "[>] Username: " USERNAME
fi

if [[ -z "$USERNAME" ]]; then
    echo "[!] Username cannot be empty."
    exit 1
fi

if ! id "$USERNAME" &>/dev/null; then
    echo "[!] User '$USERNAME' does not exist."
    exit 1
fi

if getent group kvm | grep -qw "$USERNAME"; then
    echo "[i] User '$USERNAME' is already a member of the kvm group."
    exit 0
fi

echo "[*] Adding '$USERNAME' to kvm group..."
usermod -aG kvm "$USERNAME"

echo ""
echo "[+] User '$USERNAME' added to the kvm group."
echo "[i] The user must log out and log back in for the new group membership to take effect."