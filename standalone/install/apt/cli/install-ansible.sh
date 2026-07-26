#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Installing Ansible"

echo "[*] Updating package lists..."
apt update -q

echo "[*] Installing Ansible and related tools..."
apt install -y \
    ansible \
    ansible-core \
    ansible-lint

echo ""
echo "[+] Ansible installed successfully."
