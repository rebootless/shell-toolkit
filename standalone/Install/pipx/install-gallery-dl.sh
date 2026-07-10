#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "[*] Installing gallery-dl via pipx..."

if pipx list 2>/dev/null | grep -q "gallery-dl"; then
    echo "[i] gallery-dl already installed"
else
    pipx install gallery-dl
    echo "[+] gallery-dl installed"
fi
