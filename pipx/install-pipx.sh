#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

echo ""
echo "==> Installing pipx"

if ! command -v pipx >/dev/null 2>&1; then
    echo "Updating package index..."
    sudo apt update

    echo "Installing pipx..."
    sudo apt install -y pipx
else
    echo "pipx is already installed."
fi

echo "Ensuring pipx PATH is configured..."
pipx ensurepath

export PATH="$HOME/.local/bin:$PATH"

echo ""
echo "pipx installed and PATH configured. Version: $(pipx --version)"
