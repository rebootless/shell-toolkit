#!/bin/bash
set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "[*] Updating package index..."
sudo apt update

echo "[*] Installing pipx..."
sudo apt install -y pipx

echo "[*] Ensuring pipx path is configured..."
pipx ensurepath

export PATH="$HOME/.local/bin:$PATH"

echo "[*] Installing CLI tools via pipx..."

install_if_missing() {
    local pkg="$1"

    if pipx list 2>/dev/null | grep -q "$pkg"; then
        echo "[=] $pkg already installed, skipping"
    else
        echo "[+] Installing $pkg"
        pipx install "$pkg"
    fi
}

install_if_missing yt-dlp
install_if_missing gallery-dl
install_if_missing spotdl

echo "[+] Done."
echo "[i] If commands are not found, restart shell or run: source ~/.bashrc"