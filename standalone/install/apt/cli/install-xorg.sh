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
# kitty must be installed in the same apt transaction as xorg. The xorg
# metapackage depends on <x-terminal-emulator> (an alternative dependency),
# which apt resolves to gnome-terminal by default, pulling in gvfs and other
# GNOME components. Including kitty here makes apt satisfy the alternative
# with kitty instead, so gnome-terminal is never installed.
apt install -y \
    kitty \
    xorg \
    xinit \
    x11-xserver-utils

echo ""
echo "Xorg window system installed successfully."
