#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Thumbnail cache cleanup"
THUMB_CLEANED=0

for home in /root /home/*; do
    THUMB_DIR="$home/.cache/thumbnails"
    if [[ -d "$THUMB_DIR" ]]; then
        rm -rf "${THUMB_DIR:?}"/* 2>/dev/null || true
        ((THUMB_CLEANED++))
    fi
done

if [[ $THUMB_CLEANED -gt 0 ]]; then
    echo "[+] Cleared thumbnail caches in $THUMB_CLEANED user director$([[ $THUMB_CLEANED -eq 1 ]] && echo y || echo ies)."
else
    echo "[i] No thumbnail caches found."
fi
