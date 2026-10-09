#!/bin/bash

# ---DOC-START---
# summary: Remove unused Flatpak runtimes and clear Flatpak cache.
# description: |
#   Removes unused Flatpak runtimes with `flatpak uninstall --unused`
#   and clears cached repository data under the user's and system's
#   Flatpak cache directories.
#
#   - Usage: `./cleanup-flatpak.sh [--yes] [--dry-run]`
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

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak is not installed, skipping..."
    exit 0
fi

echo "==> Flatpak cleanup"

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run: would run: flatpak uninstall --unused -y"
    echo "Dry-run: would clear /var/tmp/flatpak-cache/*"
    echo "Dry-run: would clear /var/lib/flatpak/repo/tmp/*"
    echo "Dry-run: would clear <home>/.cache/flatpak/* for each user under /home and /root"
    echo "Dry-run complete. No changes were made."
    exit 0
fi

if [[ "$ASSUME_YES" == false ]]; then
    read -rp "Remove unused Flatpak runtimes and clear Flatpak caches? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
fi

echo "Removing unused runtimes..."
flatpak uninstall --unused -y

echo "Clearing system Flatpak cache..."
rm -rf /var/tmp/flatpak-cache/* 2>/dev/null || true
rm -rf /var/lib/flatpak/repo/tmp/* 2>/dev/null || true

echo "Clearing user Flatpak cache..."
for home in /home/*; do
    [[ -d "$home" ]] || continue
    rm -rf "$home/.cache/flatpak"/* 2>/dev/null || true
done

if [[ -d /root/.cache/flatpak ]]; then
    rm -rf /root/.cache/flatpak/* 2>/dev/null || true
fi

echo "Flatpak cleanup completed."
