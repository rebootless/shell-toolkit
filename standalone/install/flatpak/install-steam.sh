#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

echo "==> Installing Steam via Flatpak"

if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak is not installed, skipping..."
    exit 0
fi

echo "Installing Steam via Flatpak..."

flatpak install -y --user flathub com.valvesoftware.Steam

echo "Steam installed"

echo "Launch command:"
echo "  flatpak run com.valvesoftware.Steam"

echo "Installed apps:"
flatpak list | grep Steam || true
