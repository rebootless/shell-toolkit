#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "[*] Updating package index..."
sudo apt update

echo "[*] Installing pipx..."
sudo apt install -y pipx

echo "[*] Ensuring pipx PATH is configured..."
pipx ensurepath

export PATH="$HOME/.local/bin:$PATH"

echo "[+] pipx installed and PATH configured"
