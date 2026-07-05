#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "[INFO] KIO Admin is a protocol that allows users to manage files"
echo "       with administrative privileges using the admin:// URL scheme,"
echo "       which operates over D-Bus to perform file operations in a root context."
echo "       It is commonly used in KDE environments to facilitate"
echo "       administrative tasks within file managers like Dolphin."

echo "[*] Updating package lists..."
apt update

echo "[*] Installing kio-admin..."
apt install kio-admin

echo "[+] kio-admin installed successfully."
