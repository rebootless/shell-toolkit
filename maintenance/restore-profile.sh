#!/bin/bash

# ---DOC-START---
# summary: Reset ~/.profile to the distribution default.
# description: |
#   Restores `~/.profile` to the distro default.
#
#   - Usage: `./restore-profile.sh [--yes]`
#   - Backs up the current `~/.profile` with a timestamp before overwriting
#   - Restores the file from `/etc/skel/.profile`
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

PROFILE="$HOME/.profile"
SKEL_PROFILE="/etc/skel/.profile"
TS="$(date +%Y%m%d_%H%M%S)"

if [[ ! -f "$SKEL_PROFILE" ]]; then
    echo "$SKEL_PROFILE not found, cannot reset."
    exit 1
fi

echo ""
echo "This will replace ~/.profile with the default:"
echo "$SKEL_PROFILE" # SKEL_PROFILE="/etc/skel/.profile"
echo ""

if [[ "$ASSUME_YES" == true ]]; then
    CONFIRM="y"
else
    read -rp "Reset ~/.profile to the default? [y/N]: " CONFIRM
fi

case "${CONFIRM,,}" in
    y|yes)
        if [[ -f "$PROFILE" ]]; then
            cp "$PROFILE" "${PROFILE}.bak.${TS}"
            echo "~/.profile backed up to ${PROFILE}.bak.${TS}"
        fi
        cp "$SKEL_PROFILE" "$PROFILE"
        echo "~/.profile reset to $SKEL_PROFILE."
        echo
        echo "Apply changes now with: source ~/.profile"
        ;;
    n|no|"")
        echo "Cancelled, ~/.profile left unchanged."
        ;;
    *)
        echo "Invalid input -> skipping ..."
        ;;
esac
