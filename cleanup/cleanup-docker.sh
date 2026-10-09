#!/bin/bash

# ---DOC-START---
# summary: Clean unused Docker data (images, containers, volumes).
# description: |
#   Prunes Docker system with confirmation prompts.
#
#   - Usage: `./cleanup-docker.sh [--yes] [--dry-run]`
#   - Basic prune removes dangling images, stopped containers, and unused networks
#   - `--yes` also confirms the more destructive removal of unused images and volumes
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
    echo "  --yes         Skip confirmation prompts (includes removing unused images/volumes)"
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

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed."
    exit 0
fi

echo "==> Docker cleanup"

if [[ "$DRY_RUN" == true ]]; then
    echo "Dry-run: would run: docker system prune -f"
    echo "Dry-run: (if confirmed) would also run: docker system prune -af --volumes"
    echo "Dry-run complete. No changes were made."
    exit 0
fi

confirm() {
    local prompt="$1"
    if [[ "$ASSUME_YES" == true ]]; then
        return 0
    fi
    read -rp "$prompt (y/N): " CONFIRM
    [[ "$CONFIRM" =~ ^[Yy]$ ]]
}

if confirm "Prune unused Docker data (dangling images, stopped containers, networks)?"; then
    docker system prune -f
    echo "Basic Docker prune completed."

    if confirm "Also remove unused images and volumes? This is destructive."; then
        docker system prune -af --volumes
        echo "Docker images and volumes removed."
    else
        echo "Skipped volumes and unused images."
    fi
else
    echo "Docker cleanup skipped."
fi
