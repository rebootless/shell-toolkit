#!/bin/bash

# ---DOC-START---
# summary: Install the latest Zafiro icon themes from the official GitHub releases.
# description: |
#   Downloads the latest Zafiro Icons Dark and Light archives from the official GitHub
#   releases and installs them into the user's local icon directory.
#
#   Install path:
#   - ${XDG_DATA_HOME:-$HOME/.local/share}/icons
#
#   Installed themes:
#   - Zafiro-Icons-Dark
#   - Zafiro-Icons-Light
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

REPO="zayronxio/Zafiro-icons"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

ARCHIVES=(
    "Zafiro-Icons-Dark.tar.xz"
    "Zafiro-Icons-Light.tar.xz"
)

echo "Installing dependencies..."

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y curl tar
fi

echo ""
echo "Fetching latest release information..."

TAG="$(
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p'
)"

if [[ -z "$TAG" ]]; then
    echo "Failed to determine the latest release." >&2
    exit 1
fi

mkdir -p "$ICON_DIR"

echo ""
echo "==> Installing Zafiro Icons"

for ARCHIVE in "${ARCHIVES[@]}"; do
    echo ""
    echo "Installing ${ARCHIVE%.tar.xz}..."

    curl -fsSL \
        "https://github.com/${REPO}/releases/download/${TAG}/${ARCHIVE}" \
        -o "${TMP_DIR}/${ARCHIVE}"

    tar -xJf \
        "${TMP_DIR}/${ARCHIVE}" \
        -C "${ICON_DIR}"
done

echo ""
echo "==> Summary"

echo ""
echo "Zafiro icon themes installed successfully."

echo ""
echo "Installed themes:"
echo "  - Zafiro-Icons-Dark"
echo "  - Zafiro-Icons-Light"

echo ""
echo "Location:"
echo "  ${ICON_DIR}"
