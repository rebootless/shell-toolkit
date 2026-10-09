#!/bin/bash

# ---DOC-START---
# summary: Reset ~/.bashrc to the distribution default.
# description: |
#   Restores `~/.bashrc` to the distro default.
#
#   - Usage: `./restore-bashrc.sh [--yes]`
#   - Backs up the current `~/.bashrc` with a timestamp before overwriting
#   - Restores the file from `/etc/skel/.bashrc`
#   - Requires explicit confirmation before making changes, unless `--yes` is passed
# sudo: false
# interactive: true
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

usage() {
    echo "Usage: $0 [--yes]"
    echo ""
    echo "  --yes         Skip the confirmation prompt"
    echo "  -h, --help    Show this help message"
}

ASSUME_YES=false

while [ $# -gt 0 ]; do
    case "$1" in
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

BASHRC="$HOME/.bashrc"
SKEL_BASHRC="/etc/skel/.bashrc"
TS="$(date +%Y%m%d_%H%M%S)"

if [[ ! -f "$SKEL_BASHRC" ]]; then
    echo "$SKEL_BASHRC not found, cannot reset."
    exit 1
fi

echo ""
echo "This will replace ~/.bashrc with the default:"
echo "$SKEL_BASHRC" # SKEL_BASHRC="/etc/skel/.bashrc"
echo ""

if [[ "$ASSUME_YES" == true ]]; then
    CONFIRM="y"
else
    read -rp "Reset ~/.bashrc to the default? [y/N]: " CONFIRM
fi

case "${CONFIRM,,}" in
    y|yes)
        if [[ -f "$BASHRC" ]]; then
            cp "$BASHRC" "${BASHRC}.bak.${TS}"
            echo "~/.bashrc backed up to ${BASHRC}.bak.${TS}"
        fi
        cp "$SKEL_BASHRC" "$BASHRC"
        echo "~/.bashrc reset to $SKEL_BASHRC."
        echo
        echo "Apply changes now with: source ~/.bashrc"
        ;;
    n|no|"")
        echo "Cancelled, ~/.bashrc left unchanged."
        ;;
    *)
        echo "Invalid input -> skipping ..."
        ;;
esac
