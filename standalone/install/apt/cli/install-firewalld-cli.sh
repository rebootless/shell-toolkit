#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Installing Firewalld CLI"

echo "[*] Updating package lists..."
apt update -q

echo "[*] Installing firewalld..."
apt install -y firewalld

echo "[*] Enabling and starting firewalld service..."
systemctl enable --now firewalld

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    echo "[!] ufw is currently active. Running both ufw and firewalld can cause"
    echo "    conflicting rules. Consider disabling ufw: 'sudo ufw disable'"
fi

echo ""
echo "[+] firewalld installed successfully."
echo "[i] Launch the CLI with: 'firewall-cmd'"
