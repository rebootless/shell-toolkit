#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Installing ghostwriter"

if command -v ghostwriter >/dev/null 2>&1; then
    echo "[i] ghostwritert is already installed, skipping..."
    exit 0
fi

echo "[*] Updating package lists..."
apt update -q

echo "[*] Installing ghostwriter..."
apt install -y ghostwriter

echo ""
echo "[+] ghostwriter installed successfully."
