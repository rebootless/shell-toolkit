#!/bin/bash

# ---DOC-START---
# summary: Install popular [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) from the official releases.
# description: |
#   Downloads and installs several popular Nerd Fonts from the official Nerd Fonts GitHub releases.
#   Install path: `/usr/local/share/fonts/NerdFonts`
#
#   Installed fonts:
#   - JetBrainsMono
#   - FiraCode
#   - Hack
#   - Meslo
#   - SourceCodePro
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script." >&2
    exit 1
fi

FONT_DIR="/usr/local/share/fonts/NerdFonts"
TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

FONTS=(
    JetBrainsMono
    FiraCode
    Hack
    Meslo
    SourceCodePro
)

echo "Updating package lists..."
apt-get update

echo "Installing dependencies..."
apt-get install -y curl unzip fontconfig

echo "==> Installing Nerd Fonts"

mkdir -p "$FONT_DIR"

for FONT in "${FONTS[@]}"; do
    echo ""
    echo "Installing ${FONT}..."

    rm -rf "${FONT_DIR}/${FONT}"

    mkdir -p "${FONT_DIR}/${FONT}"

    curl -fsSL \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${FONT}.zip" \
        -o "${TMP_DIR}/${FONT}.zip"

    unzip -oq \
        "${TMP_DIR}/${FONT}.zip" \
        -d "${FONT_DIR}/${FONT}"
done

echo ""
echo "Updating font cache..."
fc-cache -fv

echo ""
echo "==> Summary"

echo ""
echo "Nerd Fonts installed successfully."

echo ""
echo "Installed fonts:"
for FONT in "${FONTS[@]}"; do
    echo "  - ${FONT} Nerd Font"
done
