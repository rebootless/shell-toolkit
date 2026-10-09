#!/bin/bash

# ---DOC-START---
# summary: Clear thumbnail caches for all users.
# description: |
#   Removes thumbnail cache from all home directories.
#
#   - Usage: `./cleanup-thumbnails.sh [--yes] [--dry-run]`
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
    echo "  --dry-run     Show what would be cleared, without making changes"
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

echo "==> Thumbnail cache cleanup"

FOUND_DIRS=()
for home in /root /home/*; do
    THUMB_DIR="$home/.cache/thumbnails"
    if [[ -d "$THUMB_DIR" ]]; then
        FOUND_DIRS+=("$THUMB_DIR")
    fi
done

if [[ ${#FOUND_DIRS[@]} -eq 0 ]]; then
    echo "No thumbnail caches found."
    exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run: would clear the following thumbnail caches:"
    printf ' - %s\n' "${FOUND_DIRS[@]}"
    echo "Dry-run complete. No changes were made."
    exit 0
fi

if [[ "$ASSUME_YES" == false ]]; then
    echo "The following thumbnail caches will be cleared:"
    printf ' - %s\n' "${FOUND_DIRS[@]}"
    read -rp "Proceed? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
fi

THUMB_CLEANED=0
for THUMB_DIR in "${FOUND_DIRS[@]}"; do
    rm -rf "${THUMB_DIR:?}"/* 2>/dev/null || true
    ((THUMB_CLEANED++))
done

echo "Cleared thumbnail caches in $THUMB_CLEANED user director$([[ $THUMB_CLEANED -eq 1 ]] && echo y || echo ies)."
