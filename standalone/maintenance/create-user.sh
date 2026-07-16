#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Create local user"

USERNAME=""
PASSWORD=""

# Read username
if read -r -t 0; then
    read -r USERNAME
    read -r PASSWORD || true
else
    read -rp "[>] Username: " USERNAME
    read -rsp "[>] Password (leave empty for none): " PASSWORD
    echo
fi

if [[ -z "$USERNAME" ]]; then
    echo "[!] Username cannot be empty."
    exit 1
fi

# chpasswd uses "user:password"
if [[ "$PASSWORD" == *:* ]]; then
    echo "[!] Password must not contain ':'."
    exit 1
fi

if id "$USERNAME" &>/dev/null; then
    echo "[i] User '$USERNAME' already exists."
    exit 0
fi

echo "[*] Creating user '$USERNAME'..."
adduser --disabled-password --gecos "" "$USERNAME"

if [[ -n "$PASSWORD" ]]; then
    printf '%s:%s\n' "$USERNAME" "$PASSWORD" | chpasswd
    echo "[+] Password set."
else
    echo "[i] No password specified."
fi

echo
echo "[+] User '$USERNAME' created successfully."
