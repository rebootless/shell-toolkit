#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[*] Installing Steam via Flatpak..."

flatpak install -y flathub com.valvesoftware.Steam

echo "[*] Steam installed"

echo "[INFO] Launch command:"
echo "flatpak run com.valvesoftware.Steam"

echo "[INFO] Installed apps:"
flatpak list | grep steam || true
