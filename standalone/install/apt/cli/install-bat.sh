#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Installing bat"

if command -v bat >/dev/null 2>&1; then
    echo "[i] bat is already installed, skipping..."
    exit 0
fi

echo "[*] Updating package lists..."
apt update -q

echo "[*] Installing bat..."
apt install -y bat

if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    echo "[*] Linking batcat -> /usr/local/bin/bat..."
    ln -sf "$(command -v batcat)" /usr/local/bin/bat
fi

echo ""
echo "[+] bat installed successfully."
