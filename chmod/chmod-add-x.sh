#!/bin/bash

# ---DOC-START---
# summary: Recursively add execute permission to files in a path.
# description: |
#   Recursively adds the execute bit on all files under a given path.
#
#   - Usage: `./chmod-add-x.sh [--path <path>] [--dry-run] [--yes]`
#   - If `--path` is omitted, the directory containing this script is used.
#   - No root required unless the target path requires elevated access
# sudo: false
# interactive: true
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

usage() {
    echo "Usage: $0 [--path <path>] [--dry-run] [--yes]"
    echo ""
    echo "  --path <path>   Target path (default: directory containing this script)"
    echo "  --dry-run       Show what would be changed, without applying it"
    echo "  --yes           Skip the confirmation prompt"
    echo "  -h, --help      Show this help message"
}

TARGET_PATH=""
DRY_RUN=false
ASSUME_YES=false

while [ $# -gt 0 ]; do
    case "$1" in
        --path)
            [ $# -ge 2 ] || { echo "Error: --path requires an argument."; exit 1; }
            TARGET_PATH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --yes)
            ASSUME_YES=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown option '$1'"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$TARGET_PATH" ]; then
    TARGET_PATH="$(dirname "$(readlink -f "$0")")"
fi

if [ ! -e "$TARGET_PATH" ]; then
    echo "Error: Path '$TARGET_PATH' does not exist."
    exit 1
fi

if ! command -v tree &> /dev/null; then
    echo "'tree' is not installed. Trying to install..."
    if [ "$EUID" -ne 0 ]; then
        echo "Error: 'tree' is missing and root privileges are required to install it."
        echo "Please run:"
        echo "  sudo apt update && sudo apt install tree"
        exit 1
    fi
    apt-get update
    apt-get install -y tree
fi

ABS_PATH=$(readlink -f "$TARGET_PATH")

PREVENT_PATHS=(
    "/"
    "/boot"
    "/efi"
    "/etc"
    "/bin"
    "/sbin"
    "/usr"
    "/lib"
    "/lib64"
    "/libexec"
    "/var"
    "/opt"
    "/srv"
    "/sys"
    "/proc"
    "/dev"
    "/run"
    "/home"
    "/root"
    "/mnt"
    "/media"
)

for SYS_PATH in "${PREVENT_PATHS[@]}"; do
    if [[ "$ABS_PATH" == "$SYS_PATH" ]]; then
        echo "Operations on system directory '$SYS_PATH' are forbidden for safety!"
        exit 1
    fi
done

echo "========================================================================="
usage
echo ""
echo " Target path: $ABS_PATH"
echo " Action:      Add executable permission (+x)"
if [ "$DRY_RUN" = true ]; then
    echo " Mode:        Dry-run (no changes will be made)"
fi
echo "========================================================================="
echo "Files to be modified:"

if [ -d "$ABS_PATH" ]; then
    tree -F "$ABS_PATH"
else
    echo "  -> $ABS_PATH (Single file)"
fi

echo "========================================================================="

if [ "$DRY_RUN" = false ] && [ "$ASSUME_YES" = false ]; then
    read -rp "Are you sure you want to add (+x) to these files? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
fi

if [ "$DRY_RUN" = true ]; then
    echo "Dry-run: the following would be executed:"
    if [ -f "$ABS_PATH" ]; then
        echo "  chmod +x -- $ABS_PATH"
    else
        find "$ABS_PATH" -type f -print | while IFS= read -r f; do
            echo "  chmod +x -- $f"
        done
    fi
    echo "Dry-run complete. No changes were made."
    exit 0
fi

echo "Adding executable permission (+x)..."

if [ -f "$ABS_PATH" ]; then
    chmod +x "$ABS_PATH"
else
    find "$ABS_PATH" -type f -exec chmod +x {} +
fi

echo "Done."
