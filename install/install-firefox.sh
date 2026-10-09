#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing Firefox"

if command -v firefox >/dev/null 2>&1; then
    echo "Firefox is already installed, skipping..."
    exit 0
fi

echo "Updating package lists..."
apt update -q

if apt-cache show firefox >/dev/null 2>&1; then
    PKG="firefox"
elif apt-cache show firefox-esr >/dev/null 2>&1; then
    PKG="firefox-esr"
else
    echo "No Firefox package (firefox / firefox-esr) found in configured repositories."
    exit 1
fi

echo "Installing Firefox (${PKG})..."
apt install -y "$PKG"

echo ""
echo "Firefox installed successfully."
