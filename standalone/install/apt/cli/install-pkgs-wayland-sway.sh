#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing Wayland/Sway core environment"

echo "Updating package lists..."
apt update -q

echo "Installing Wayland/Sway core environment..."
apt install -y \
    sway \
    swaybg \
    wofi \
    waybar \
    xwayland \
    xdg-desktop-portal-wlr \
    xdg-desktop-portal-gtk \
    fuse3 \
    libfuse2t64 \
    libnss3 \
    qt6-wayland \
    qtwayland5

echo ""
echo "Wayland/Sway core environment installed successfully."
