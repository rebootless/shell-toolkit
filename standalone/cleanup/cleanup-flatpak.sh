#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

if ! command -v flatpak >/dev/null 2>&1; then
    echo "[i] flatpak is not installed, skipping..."
    exit 0
fi

echo "==> Flatpak cleanup"

echo "[*] Removing unused runtimes..."
flatpak uninstall --unused -y

echo "[*] Clearing system Flatpak cache..."
rm -rf /var/tmp/flatpak-cache/* 2>/dev/null || true
rm -rf /var/lib/flatpak/repo/tmp/* 2>/dev/null || true

echo "[*] Clearing user Flatpak cache..."
for home in /home/*; do
    [[ -d "$home" ]] || continue
    rm -rf "$home/.cache/flatpak"/* 2>/dev/null || true
done

if [[ -d /root/.cache/flatpak ]]; then
    rm -rf /root/.cache/flatpak/* 2>/dev/null || true
fi

echo "[+] Flatpak cleanup completed."
