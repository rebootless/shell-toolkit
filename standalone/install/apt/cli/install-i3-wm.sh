#!/bin/bash
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing i3 window manager"

echo "Updating package lists..."
apt update -q

echo "Installing i3 window manager..."
apt install -y \
    i3-wm \
    i3status

echo ""
echo "i3 window manager installed successfully."
