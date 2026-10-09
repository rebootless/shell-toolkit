#!/bin/bash

# ---DOC-START---
# summary: Install Steam from Flathub.
# description: |
#   Installs [Steam](https://store.steampowered.com) from Flathub.
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

echo "==> Installing Steam via Flatpak"

if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak is not installed, skipping..."
    exit 0
fi

echo "Installing Steam via Flatpak..."

flatpak install -y flathub com.valvesoftware.Steam

echo "Steam installed"

echo "Launch command:"
echo "  flatpak run com.valvesoftware.Steam"

echo "Installed apps:"
flatpak list | grep Steam || true
