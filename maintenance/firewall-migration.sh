#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

if command -v ufw >/dev/null 2>&1; then
    echo "[*] Disabling UFW..."
    ufw disable || true

    echo "[*] Resetting UFW..."
    echo "y" | ufw reset

    echo "[*] Removing UFW..."
    apt-get purge -y ufw
    apt-get autoremove -y
fi

echo "[*] Updating package lists..."
apt-get update

echo "[*] Installing firewalld..."
apt-get install -y firewalld

echo "[*] Enabling and starting firewalld..."
systemctl enable --now firewalld

echo "[*] Allowing SSH..."
firewall-cmd --permanent --add-service=ssh

echo "[*] Reloading firewall rules..."
firewall-cmd --reload

echo "[+] Migration from UFW to firewalld completed."
