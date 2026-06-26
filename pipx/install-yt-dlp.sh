#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "[*] Installing yt-dlp via pipx..."

if pipx list 2>/dev/null | grep -q "yt-dlp"; then
    echo "[i] yt-dlp already installed"
else
    pipx install yt-dlp
    echo "[+] yt-dlp installed"
fi
