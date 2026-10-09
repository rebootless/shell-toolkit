#!/bin/bash

# ---DOC-START---
# summary: Clean APT cache and remove orphaned packages.
# description: |
#   Runs apt-get autoremove, autoclean, and clean to free disk space.
#
#   - Usage: `./cleanup-apt.sh [--yes] [--dry-run]`
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

echo "==> APT cleanup"

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run: would run the following:"
    echo "  apt-get autoremove -y"
    echo "  apt-get autoclean -y"
    echo "  apt-get clean"
    echo "Dry-run complete. No changes were made."
    exit 0
fi

if [[ "$ASSUME_YES" == false ]]; then
    read -rp "Remove orphaned packages and clear the APT cache? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
fi

echo "Removing orphaned packages..."
apt-get autoremove -y
echo "Removing obsolete .deb files..."
apt-get autoclean -y
echo "Clearing APT cache..."
apt-get clean

echo "APT cleanup completed."
