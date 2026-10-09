#!/bin/bash

# ---DOC-START---
# summary: Clear cache, cookies, and history for Firefox.
# description: |
#   Stops Firefox and clears cookies, history, cache, etc.
#
#   - Usage: `./cleanup-browser-firefox.sh [--yes] [--dry-run]`
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

FIREFOX_DIR="$HOME/.mozilla/firefox"

if [[ ! -d "$FIREFOX_DIR" ]]; then
    echo "Firefox not found."
    exit 0
fi

FIND_ARGS=(-name "places.sqlite" \
        -o -name "cookies.sqlite" \
        -o -name "favicons.sqlite")

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run: would stop Firefox (pkill firefox)."
    echo "Dry-run: would delete the following files under $FIREFOX_DIR:"
    find "$FIREFOX_DIR" -type f \( "${FIND_ARGS[@]}" \) -print
    echo "Dry-run: would clear ${HOME}/.cache/mozilla/firefox/*"
    echo "Dry-run complete. No changes were made."
    exit 0
fi

if [[ "$ASSUME_YES" == false ]]; then
    read -rp "Stop Firefox and clear its cookies, history, and cache? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
fi

echo "Stopping Firefox (if running)..."
pkill firefox || true

echo "Cleaning Firefox..."
find "$FIREFOX_DIR" -type f \( "${FIND_ARGS[@]}" \) -delete
rm -rf "${HOME}/.cache/mozilla/firefox"/* 2>/dev/null || true
echo "Firefox cleaned."
