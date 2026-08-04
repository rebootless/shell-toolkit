#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing polkit agent and system hotkey helpers"

echo "Updating package lists..."
apt update -q

echo "Installing polkit agent and system hotkey helpers..."
apt install -y \
    lxpolkit \
    brightnessctl

echo ""
echo "Polkit agent and system hotkey helpers installed successfully."
