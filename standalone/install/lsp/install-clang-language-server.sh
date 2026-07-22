#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Installing Clangd"

if command -v clangd >/dev/null 2>&1; then
    echo "[*] clangd already installed, skipping..."
    exit 0
fi

apt-get update
apt-get install -y clangd

echo ""
echo "[+] clangd installed successfully."
