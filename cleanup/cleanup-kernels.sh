#!/bin/bash

# ---DOC-START---
# summary: Remove old kernel packages (keeping current kernel).
# description: |
#   Detects and optionally removes old Linux kernels.
#
#   - Usage: `./cleanup-kernels.sh [--yes] [--dry-run]`
# sudo: true
# interactive: true
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

usage() {
    echo "Usage: $0 [--yes] [--dry-run]"
    echo
    echo "  --yes         Skip the confirmation prompt"
    echo "  --dry-run     Show what would be removed, without making changes"
    echo "  -h, --help    Show this help message"
}

DRY_RUN=false
ASSUME_YES=false

while [ $# -gt 0 ]; do
    case "$1" in
        --yes) ASSUME_YES=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Error: unknown option '$1'"; usage; exit 1 ;;
    esac
done

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

CURRENT_KERNEL=$(uname -r)
echo "==> Old kernels cleanup"
echo "Current kernel: $CURRENT_KERNEL"

mapfile -t OLD_KERNELS < <(dpkg -l 'linux-image-*' 2>/dev/null \
    | awk '/^ii/{print $2}' \
    | grep -v "$CURRENT_KERNEL" || true)

if [[ ${#OLD_KERNELS[@]} -eq 0 ]]; then
    echo "No old kernels found."
    exit 0
fi

echo "Found old kernels:"
printf ' - %s\n' "${OLD_KERNELS[@]}"

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run: would run: apt-get purge -y ${OLD_KERNELS[*]}"
    echo "Dry-run complete. No changes were made."
    exit 0
fi

if [[ "$ASSUME_YES" == false ]]; then
    read -rp "Remove old kernel packages? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Old kernel cleanup skipped."
        exit 0
    fi
fi

apt-get purge -y "${OLD_KERNELS[@]}"
echo "Old kernels removed."
