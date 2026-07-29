#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing Inkscape"

if command -v inkscape >/dev/null 2>&1; then
    echo "Inkscape is already installed, skipping..."
    exit 0
fi

echo "Updating package lists..."
apt update -q

echo "Installing Inkscape..."
apt install -y inkscape

echo ""
echo "Inkscape installed successfully."
