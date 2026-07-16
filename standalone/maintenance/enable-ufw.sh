#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

if ! command -v ufw >/dev/null 2>&1; then
    echo "[!] UFW is not installed."
    exit 1
fi

echo "[*] Allowing SSH..."
ufw allow OpenSSH

echo "[*] Enabling UFW..."
ufw --force enable

if systemctl is-active --quiet firewalld; then
    echo "[!] Firewalld is currently active. Running both Firewalld and UFW can"
    echo "    cause conflicting rules. Consider disabling Firewalld:"
    echo "    'sudo systemctl disable --now firewalld'"
fi

echo "[SUCCESS] UFW has been enabled."
