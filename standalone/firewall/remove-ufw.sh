#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

if ! command -v ufw >/dev/null 2>&1; then
    echo "UFW is not installed. Nothing to do."
    exit 0
fi

echo "Resetting UFW..."
echo "y" | ufw reset

echo "Removing UFW..."
apt-get remove -y ufw

echo "Removing unused dependencies..."
apt-get autoremove -y

echo "UFW has been removed."
