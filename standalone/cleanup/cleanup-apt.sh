#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> APT cleanup"
echo "[*] Removing orphaned packages..."
apt-get autoremove -y
echo "[*] Removing obsolete .deb files..."
apt-get autoclean -y
echo "[*] Clearing APT cache..."
apt-get clean

echo "[+] APT cleanup completed."
