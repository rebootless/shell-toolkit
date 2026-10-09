#!/bin/bash

# ---DOC-START---
# summary: Clean temporary files in /tmp and /var/tmp.
# description: |
#   Removes files older than 7 days from temporary directories.
#
#   - Usage: `./cleanup-temp.sh [--yes] [--dry-run]`
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
    echo "  --dry-run     Show what would be deleted, without making changes"
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

LOG_AGE_DAYS=7

echo "==> Temp files cleanup"

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run: files older than ${LOG_AGE_DAYS} days under /tmp:"
    find /tmp -mindepth 1 -mtime +${LOG_AGE_DAYS} -print 2>/dev/null || true
    echo "Dry-run: files older than ${LOG_AGE_DAYS} days under /var/tmp:"
    find /var/tmp -mindepth 1 -mtime +${LOG_AGE_DAYS} -print 2>/dev/null || true
    echo "Dry-run complete. No changes were made."
    exit 0
fi

if [[ "$ASSUME_YES" == false ]]; then
    read -rp "Delete files older than ${LOG_AGE_DAYS} days from /tmp and /var/tmp? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
fi

echo "Cleaning /tmp..."
find /tmp -mindepth 1 -mtime +${LOG_AGE_DAYS} -print -delete 2>/dev/null || true

echo "Cleaning /var/tmp..."
find /var/tmp -mindepth 1 -mtime +${LOG_AGE_DAYS} -print -delete 2>/dev/null || true

echo "Temporary files cleaned."
