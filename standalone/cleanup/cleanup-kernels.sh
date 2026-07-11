#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

CURRENT_KERNEL=$(uname -r)
echo "==> Old kernels cleanup"
echo "[i] Current kernel: $CURRENT_KERNEL"

mapfile -t OLD_KERNELS < <(dpkg -l 'linux-image-*' 2>/dev/null \
    | awk '/^ii/{print $2}' \
    | grep -v "$CURRENT_KERNEL" || true)

if [[ ${#OLD_KERNELS[@]} -gt 0 ]]; then
    echo "[i] Found old kernels:"
    printf ' - %s\n' "${OLD_KERNELS[@]}"
    read -rp "[?] Remove old kernel packages? [y/N]: " CHOICE
    case "${CHOICE,,}" in
        y|yes)
            apt-get purge -y "${OLD_KERNELS[@]}"
            echo "[+] Old kernels removed."
            ;;
        *)
            echo "[i] Old kernel cleanup skipped."
            ;;
    esac
else
    echo "[i] No old kernels found."
fi
