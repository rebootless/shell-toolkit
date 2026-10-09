#!/bin/bash

# ---DOC-START---
# summary: Install Discord from Flathub.
# description: |
#   Installs [Discord](https://discord.com) from Flathub.
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

echo "==> Installing Discord via Flatpak"

if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak is not installed, skipping..."
    exit 0
fi

echo "Installing Discord via Flatpak..."

flatpak install -y flathub com.discordapp.Discord

echo "Discord installed"

echo "Launch command:"
echo "  flatpak run com.discordapp.Discord"

echo "Installed apps:"
flatpak list | grep discord || true
