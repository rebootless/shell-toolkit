#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[1/3] Installing Flatpak..."
sudo apt update
sudo apt install -y flatpak

echo "[2/3] Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "[3/3] KDE Discover Flatpak backend..."
if dpkg -s plasma-discover >/dev/null 2>&1; then
    sudo apt install -y plasma-discover-backend-flatpak
    echo "[+] Discover Flatpak support enabled"
else
    echo "[!] KDE Discover not installed, skipping integration"
fi

echo "[+] Flatpak setup complete"
