#!/bin/bash
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "---------------Installing Flameshot--------------"

if command -v flameshot >/dev/null 2>&1; then
    echo "[i] Flameshot is already installed, skipping."
    exit 0
fi

echo "[*] Updating package lists..."
apt update -q

echo "[*] Installing Flameshot..."
apt install -y flameshot

echo ""
echo "[+] Flameshot installed successfully."
