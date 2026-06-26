#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[*] Installing Telegram via Flatpak..."

flatpak install -y flathub org.telegram.desktop

echo "[*] Telegram installed"

echo "[INFO] Launch command:"
echo "flatpak run org.telegram.desktop"

echo "[INFO] Installed apps:"
flatpak list | grep telegram || true
