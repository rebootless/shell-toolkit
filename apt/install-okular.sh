#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "[*] Updating package lists..."
apt update

echo "[*] Installing Okular and additional backends..."
apt install -y \
    okular \
    okular-doc \
    okular-extra-backends \
    okular-backend-odt \
    okular-backend-odp

echo "[+] Okular installed successfully."
