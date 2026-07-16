#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Installing UFW"

echo "[*] Updating package lists..."
apt update -q

echo "[*] Installing UFW..."
apt install -y ufw

echo "[*] Allowing SSH..."
ufw allow OpenSSH

echo "[*] Enabling UFW..."
ufw --force enable

if systemctl is-active --quiet firewalld; then
    echo "[!] Firewalld is currently active. Running both Firewalld and UFW can"
    echo "    cause conflicting rules. Consider disabling Firewalld:"
    echo "    'sudo systemctl disable --now firewalld'"
fi

echo ""
echo "[+] UFW installed successfully."
echo "[i] Check firewall status with: 'ufw status verbose'"
