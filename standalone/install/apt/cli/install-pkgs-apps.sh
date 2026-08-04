#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing applications"

echo "Updating package lists..."
apt update -q

echo "Installing applications..."
apt install -y \
    firefox-esr \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    xarchiver \
    python3-pil \
    tty-clock \
    chafa \
    cmus \
    nsxiv \
    cava \
    vlc \
    flameshot \
    copyq \
    wl-clipboard \
    fastfetch

echo ""
echo "Applications installed successfully."
