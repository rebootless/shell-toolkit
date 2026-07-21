#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

LOG_AGE_DAYS=7

echo "==> Temp files cleanup"
echo "[*] Cleaning /tmp..."
find /tmp -mindepth 1 -mtime +${LOG_AGE_DAYS} -print -delete 2>/dev/null || true

echo "[*] Cleaning /var/tmp..."
find /var/tmp -mindepth 1 -mtime +${LOG_AGE_DAYS} -print -delete 2>/dev/null || true

echo "[+] Temporary files cleaned."
