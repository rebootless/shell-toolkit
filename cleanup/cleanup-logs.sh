#!/bin/bash

# ---DOC-START---
# summary: Clean old journald logs and rotated logs.
# description: |
#   Vacuums journald and removes rotated logs older than 7 days.
#
#   - Usage: `./cleanup-logs.sh [--yes] [--dry-run]`
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

LOG_AGE_DAYS=7

echo "==> Log cleanup"

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run: would run: journalctl --vacuum-time=${LOG_AGE_DAYS}d"
    echo "Dry-run: rotated logs older than ${LOG_AGE_DAYS} days under /var/log:"
    find /var/log -type f \( -name "*.gz" -o -name "*.[0-9]" -o -name "*.old" \) \
        -mtime +${LOG_AGE_DAYS} -print 2>/dev/null || true
    echo "Dry-run complete. No changes were made."
    exit 0
fi

if [[ "$ASSUME_YES" == false ]]; then
    read -rp "Vacuum journald and delete rotated logs older than ${LOG_AGE_DAYS} days? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
fi

echo "Vacuuming journald logs older than ${LOG_AGE_DAYS} days..."
journalctl --vacuum-time=${LOG_AGE_DAYS}d >/dev/null

echo "Removing old rotated logs in /var/log..."
find /var/log -type f \( -name "*.gz" -o -name "*.[0-9]" -o -name "*.old" \) \
    -mtime +${LOG_AGE_DAYS} -print -delete

echo "Log cleanup completed."
