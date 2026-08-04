#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing notification, screenshot, and speech tools"

echo "Updating package lists..."
apt update -q

echo "Installing notification, screenshot, and speech tools..."
apt install -y \
    sway-notification-center \
    grim \
    slurp \
    speech-dispatcher \
    libnotify-bin

echo ""
echo "Notification, screenshot, and speech tools installed successfully."
