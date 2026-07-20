#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Installing zoxide"

if command -v zoxide >/dev/null 2>&1; then
    echo "[i] zoxide is already installed, skipping..."
    exit 0
fi

echo "[*] Updating package lists..."
apt update -q

if apt-cache show zoxide >/dev/null 2>&1; then
    echo "[*] Installing zoxide from apt..."
    apt install -y zoxide
else
    echo "[i] zoxide package not found in configured repositories."
    echo "[*] Installing dependencies for the upstream install script..."
    apt install -y curl

    TARGET_USER="${SUDO_USER:-root}"
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

    echo "[*] Installing zoxide via the official install script for user ${TARGET_USER}..."
    sudo -u "$TARGET_USER" bash -c 'curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'

    echo "[i] zoxide was installed to ${TARGET_HOME}/.local/bin — ensure that directory is on PATH."
fi

echo ""
echo "[+] zoxide installed successfully."
echo "[i] Add to your shell rc: eval \"\$(zoxide init bash)\"  (or zsh/fish)"
