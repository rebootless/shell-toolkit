#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Grant sudo access"

if ! dpkg -s sudo >/dev/null 2>&1; then
    echo "[!] sudo group does not exist."
    echo "    Install sudo first."
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

if getent group sudo | grep -qw "$USERNAME"; then
    echo "[i] User '$USERNAME' is already a member of the sudo group."
    exit 0
fi

echo "[*] Adding '$USERNAME' to sudo group..."
usermod -aG sudo "$USERNAME"

echo ""
echo "[+] User '$USERNAME' added to the sudo group."
echo "[i] The user must log out and log back in for the new group membership to take effect."
