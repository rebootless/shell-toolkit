#!/bin/bash
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "------------------Installing eza-----------------"

if command -v eza >/dev/null 2>&1; then
    echo "[i] eza is already installed, skipping."
    exit 0
fi

echo "[*] Updating package lists..."
apt update -q

if apt-cache show eza >/dev/null 2>&1; then
    echo "[*] Installing eza from the distribution repositories..."
    apt install -y eza
else
    echo "[i] eza package not found in configured repositories."
    echo "[*] Adding the official eza apt repository (deb.gierens.de)..."

    apt install -y gpg curl

    KEYRING="/etc/apt/keyrings/gierens.gpg"
    LIST="/etc/apt/sources.list.d/gierens.list"

    mkdir -p /etc/apt/keyrings
    curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
        | gpg --dearmor -o "$KEYRING"
    echo "deb [signed-by=${KEYRING}] http://deb.gierens.de stable main" > "$LIST"
    chmod 644 "$KEYRING" "$LIST"

    echo "[*] Updating package lists..."
    apt update -q

    echo "[*] Installing eza..."
    apt install -y eza
fi

echo ""
echo "[+] eza installed successfully."
