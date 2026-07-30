#!/bin/bash
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing Xorg window system"

echo "Updating package lists..."
apt update -q

echo "Installing Xorg window system..."
apt install -y \
    xorg \
    xinit \
    x11-xserver-utils

echo ""
echo "Xorg window system installed successfully."
