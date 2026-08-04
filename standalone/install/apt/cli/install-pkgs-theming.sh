#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing Qt/GTK theming integration tools"

echo "Updating package lists..."
apt update -q

echo "Installing Qt/GTK theming integration tools..."
apt install -y \
    qt5ct \
    qt6ct \
    nwg-look \
    adwaita-qt \
    adwaita-qt6 \
    kde-style-breeze

echo ""
echo "Qt/GTK theming integration tools installed successfully."
