#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

if ! command -v ufw >/dev/null 2>&1; then
    echo "[INFO] UFW is not installed. Nothing to do."
    exit 0
fi

echo "[*] Disabling UFW..."
ufw disable || true

echo "[SUCCESS] UFW has been disabled."
