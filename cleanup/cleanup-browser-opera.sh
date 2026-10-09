#!/bin/bash

# ---DOC-START---
# summary: Clear cache, cookies, and history for Opera.
# description: |
#   Stops Opera and clears cookies, history, cache, etc.
#
#   - Usage: `./cleanup-browser-opera.sh [--yes] [--dry-run]`
# sudo: false
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
    echo "  --dry-run     Show what would be done, without making changes"
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

OPERA_DIR="$HOME/.config/opera"

if [[ ! -d "$OPERA_DIR" ]]; then
    echo "Opera not found."
    exit 0
fi

FIND_ARGS=(-name "History" \
        -o -name "Cookies" \
        -o -name "Visited Links")

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run: would stop Opera (pkill opera)."
    echo "Dry-run: would delete the following files under $OPERA_DIR:"
    find "$OPERA_DIR" -type f \( "${FIND_ARGS[@]}" \) -print
    echo "Dry-run: would clear ${HOME}/.cache/opera/*"
    echo "Dry-run complete. No changes were made."
    exit 0
fi

if [[ "$ASSUME_YES" == false ]]; then
    read -rp "Stop Opera and clear its cookies, history, and cache? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
fi

echo "Stopping Opera (if running)..."
pkill opera || true

echo "Cleaning Opera..."
find "$OPERA_DIR" -type f \( "${FIND_ARGS[@]}" \) -delete
rm -rf "${HOME}/.cache/opera"/* 2>/dev/null || true
echo "Opera cleaned."
