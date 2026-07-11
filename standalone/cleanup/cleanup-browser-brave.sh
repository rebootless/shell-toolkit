#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "[*] Stopping Brave..."
pkill brave || true

echo "[*] Cleaning Brave..."
BRAVE_DIR="$HOME/.config/BraveSoftware/Brave-Browser"
if [[ -d "$BRAVE_DIR" ]]; then
    find "$BRAVE_DIR" -type f \( \
        -name "History" \
        -o -name "Cookies" \
        -o -name "Top Sites" \
        -o -name "Favicons" \
        -o -name "Visited Links" \
        -o -name "History-journal" \
        -o -name "History-wal" \
    \) -delete
    rm -rf "$HOME/.cache/BraveSoftware/Brave-Browser"/* 2>/dev/null || true
    echo "[+] Brave cleaned."
else
    echo "[-] Brave not found."
fi
