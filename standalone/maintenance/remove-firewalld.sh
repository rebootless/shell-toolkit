#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "[INFO] Firewalld is not installed. Nothing to do."
    exit 0
fi

echo "[*] Stopping Firewalld..."
systemctl stop firewalld || true

echo "[*] Disabling Firewalld..."
systemctl disable firewalld || true

echo "[*] Removing Firewalld..."
apt-get remove -y firewalld

echo "[*] Removing unused dependencies..."
apt-get autoremove -y

echo "[SUCCESS] Firewalld has been removed."
