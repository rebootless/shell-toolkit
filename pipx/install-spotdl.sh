#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "[*] Installing spotdl via pipx..."

if pipx list 2>/dev/null | grep -q "spotdl"; then
    echo "[i] spotdl already installed"
else
    pipx install spotdl
    echo "[+] spotdl installed"
fi
