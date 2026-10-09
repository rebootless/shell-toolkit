#!/bin/bash

# ---DOC-START---
# summary: Install Telegram Desktop from Flathub.
# description: |
#   Installs [Telegram Desktop](https://desktop.telegram.org) from Flathub.
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

echo "==> Installing Telegram via Flatpak"

if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak is not installed, skipping..."
    exit 0
fi

echo "Installing Telegram via Flatpak..."

flatpak install -y flathub org.telegram.desktop

echo "Telegram installed"

echo "Launch command:"
echo "  flatpak run org.telegram.desktop"

echo "Installed apps:"
flatpak list | grep telegram || true
