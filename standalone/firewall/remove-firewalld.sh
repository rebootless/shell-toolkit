#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "Firewalld is not installed. Nothing to do."
    exit 0
fi

echo "Removing Firewalld..."
apt-get remove -y firewalld

echo "Removing unused dependencies..."
apt-get autoremove -y

echo "Firewalld has been removed."
