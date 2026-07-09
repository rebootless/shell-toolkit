#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "[*] Stopping Edge (if running)..."
pkill msedge || true

echo "[*] Cleaning Microsoft Edge..."
EDGE_DIR="$HOME/.config/microsoft-edge"
if [[ -d "$EDGE_DIR" ]]; then
    find "$EDGE_DIR" -type f \( \
        -name "History" \
        -o -name "Cookies" \
        -o -name "Top Sites" \
        -o -name "Favicons" \
        -o -name "Visited Links" \
    \) -delete
    rm -rf "$HOME/.cache/microsoft-edge"/* 2>/dev/null || true
    echo "[+] Microsoft Edge cleaned."
else
    echo "[-] Microsoft Edge not found."
fi
