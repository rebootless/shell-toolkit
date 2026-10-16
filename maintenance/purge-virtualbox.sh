#!/bin/bash

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo ""
echo "==> Purging VirtualBox"

if command -v VBoxManage >/dev/null 2>&1; then
    echo "Removing installed Extension Packs..."

    mapfile -t EXT_PACKS < <(
        VBoxManage list extpacks 2>/dev/null |
        awk -F': ' '/^Pack name:/ {print $2}'
    )

    if ((${#EXT_PACKS[@]})); then
        for PACK in "${EXT_PACKS[@]}"; do
            echo "  Removing: ${PACK}"
            VBoxManage extpack uninstall --force "${PACK}" || true
        done
    else
        echo "No Extension Packs found."
    fi
fi

echo "Detecting VirtualBox packages..."

mapfile -t PACKAGES < <(
    dpkg -l 'virtualbox*' 2>/dev/null \
        | awk '/^(ii|rc)/ {print $2}' \
        | sort -u
)

if ((${#PACKAGES[@]})); then
    echo "Purging packages..."
    apt purge -y "${PACKAGES[@]}"
else
    echo "No VirtualBox packages found."
fi

echo ""
echo "==> Summary"

echo ""
echo "VirtualBox packages, residual configuration and installed"
echo "Extension Packs have been removed."
