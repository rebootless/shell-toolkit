#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak is not installed, skipping..."
    exit 0
fi

echo "==> Updating Flatpak applications"
flatpak update -y
echo "Flatpak applications and runtimes updated."

echo ""
echo "Flatpak applications and runtimes are up to date."
