#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[1/5] Installing Flatpak..."
sudo apt update
sudo apt install -y flatpak

echo "[2/5] Ensuring Flathub repository..."
if ! flatpak remote-list | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

echo "[3/5] Checking KDE Discover..."
if dpkg -s plasma-discover >/dev/null 2>&1; then
    echo "Discover detected → installing Flatpak backend..."
    sudo apt install -y plasma-discover-backend-flatpak
else
    echo "Discover not installed → skipping backend."
fi

echo "[4/5] Installing Flatpak apps..."

flatpak install -y flathub \
    org.telegram.desktop \
    com.discordapp.Discord \
    com.valvesoftware.Steam

flatpak list

echo "[5/5] Done."