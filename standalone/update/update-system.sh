#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Updating package index"
apt-get update
echo "[+] Package index refreshed."


echo "==> Upgrading installed packages"
apt-get upgrade -y
echo "[+] Packages upgraded."

echo ""
echo "[+] System packages are up to date."
