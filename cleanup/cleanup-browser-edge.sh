#!/bin/bash

# ---DOC-START---
# summary: Clear cache, cookies, and history for Microsoft Edge.
# description: |
#   Stops Microsoft Edge and clears cookies, history, cache, etc.
#
#   - Usage: `./cleanup-browser-edge.sh [--yes] [--dry-run]`
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

EDGE_DIR="$HOME/.config/microsoft-edge"

if [[ ! -d "$EDGE_DIR" ]]; then
    echo "Microsoft Edge not found."
    exit 0
fi

FIND_ARGS=(-name "History" \
        -o -name "Cookies" \
        -o -name "Top Sites" \
        -o -name "Favicons" \
        -o -name "Visited Links")

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run: would stop Microsoft Edge (pkill msedge)."
    echo "Dry-run: would delete the following files under $EDGE_DIR:"
    find "$EDGE_DIR" -type f \( "${FIND_ARGS[@]}" \) -print
    echo "Dry-run: would clear ${HOME}/.cache/microsoft-edge/*"
    echo "Dry-run complete. No changes were made."
    exit 0
fi

if [[ "$ASSUME_YES" == false ]]; then
    read -rp "Stop Microsoft Edge and clear its cookies, history, and cache? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
fi

echo "Stopping Microsoft Edge (if running)..."
pkill msedge || true

echo "Cleaning Microsoft Edge..."
find "$EDGE_DIR" -type f \( "${FIND_ARGS[@]}" \) -delete
rm -rf "${HOME}/.cache/microsoft-edge"/* 2>/dev/null || true
echo "Microsoft Edge cleaned."
