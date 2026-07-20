#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

LOG_AGE_DAYS=7

echo "==> Log cleanup"
echo "[*] Vacuuming journald logs older than ${LOG_AGE_DAYS} days..."
journalctl --vacuum-time=${LOG_AGE_DAYS}d >/dev/null

echo "[*] Removing old rotated logs in /var/log..."
find /var/log -type f \( -name "*.gz" -o -name "*.[0-9]" -o -name "*.old" \) \
    -mtime +${LOG_AGE_DAYS} -print -delete

echo "[+] Log cleanup completed."
