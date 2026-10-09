#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --apt             Clean APT cache
  --brave           Clean Brave Browser
  --chrome          Clean Google Chrome
  --chromium        Clean Chromium
  --docker          Clean Docker
  --edge            Clean Microsoft Edge
  --firefox         Clean Firefox
  --flatpak         Clean Flatpak
  --kernels         Remove old kernels
  --logs            Clean system logs
  --opera           Clean Opera
  --temp            Clean temporary files
  --thumbnails      Remove thumbnail cache
  --vivaldi         Clean Vivaldi

  --all             Run every cleanup task
  --yes             Skip confirmation prompts (forwarded to each subscript)
  --dry-run         Preview changes only, forwarded to each subscript
  -h, --help        Show this help
EOF
}

if [[ $# -gt 0 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
    usage
    exit 0
fi

ORIGINAL_ARGS=("$@")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP_DIR="$(cd "$SCRIPT_DIR/../cleanup" && pwd)"

TASKS=()
NEED_ROOT=false
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apt)
            TASKS+=(cleanup-apt.sh)
            NEED_ROOT=true
            ;;
        --brave)
            TASKS+=(cleanup-browser-brave.sh)
            ;;
        --chrome)
            TASKS+=(cleanup-browser-chrome.sh)
            ;;
        --chromium)
            TASKS+=(cleanup-browser-chromium.sh)
            ;;
        --docker)
            TASKS+=(cleanup-docker.sh)
            NEED_ROOT=true
            ;;
        --edge)
            TASKS+=(cleanup-browser-edge.sh)
            ;;
        --firefox)
            TASKS+=(cleanup-browser-firefox.sh)
            ;;
        --flatpak)
            TASKS+=(cleanup-flatpak.sh)
            NEED_ROOT=true
            ;;
        --kernels)
            TASKS+=(cleanup-kernels.sh)
            NEED_ROOT=true
            ;;
        --logs)
            TASKS+=(cleanup-logs.sh)
            NEED_ROOT=true
            ;;
        --opera)
            TASKS+=(cleanup-browser-opera.sh)
            ;;
        --temp)
            TASKS+=(cleanup-temp.sh)
            ;;
        --thumbnails)
            TASKS+=(cleanup-thumbnails.sh)
            ;;
        --vivaldi)
            TASKS+=(cleanup-browser-vivaldi.sh)
            ;;

        --all)
            TASKS=(
                cleanup-apt.sh
                cleanup-browser-brave.sh
                cleanup-browser-chrome.sh
                cleanup-browser-chromium.sh
                cleanup-browser-edge.sh
                cleanup-browser-firefox.sh
                cleanup-browser-opera.sh
                cleanup-browser-vivaldi.sh
                cleanup-docker.sh
                cleanup-flatpak.sh
                cleanup-kernels.sh
                cleanup-logs.sh
                cleanup-temp.sh
                cleanup-thumbnails.sh
            )
            NEED_ROOT=true
            ;;

        --yes)
            EXTRA_ARGS+=(--yes)
            ;;
        --dry-run)
            EXTRA_ARGS+=(--dry-run)
            ;;

        -h|--help)
            usage
            exit 0
            ;;

        *)
            echo "Unknown option: $1"
            echo
            usage
            exit 1
            ;;
    esac
    shift
done

if [[ ${#TASKS[@]} -eq 0 ]]; then
    usage
    exit 1
fi

if [[ "$NEED_ROOT" == true && $EUID -ne 0 ]]; then
    exec sudo "$0" "${ORIGINAL_ARGS[@]}"
fi

run_script() {
    local script="$1"

    if [[ -f "$CLEANUP_DIR/$script" ]]; then
        echo "Running $script"
        bash "$CLEANUP_DIR/$script" "${EXTRA_ARGS[@]}"
    else
        echo "Missing $script"
    fi
}

echo "Running cleanup tasks..."

for script in "${TASKS[@]}"; do
    run_script "$script"
done

echo "Done."
