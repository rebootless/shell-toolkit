#!/bin/bash

# ---DOC-START---
# summary: Install ttyd from the official GitHub release.
# description: |
#   Downloads and installs the ttyd x86_64 binary from the official GitHub release.
#   Install path: `/usr/local/bin/ttyd`
#
#   - Version: 1.7.7
#   - Architecture: x86_64
#   - Source: official ttyd GitHub release
#   - Replaces an existing ttyd binary only when the installed version differs.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

VERSION="1.7.7"
ARCH="x86_64"
INSTALL_PATH="/usr/local/bin/ttyd"
URL="https://github.com/tsl0922/ttyd/releases/download/${VERSION}/ttyd.${ARCH}"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

if [[ "$(uname -m)" != "$ARCH" ]]; then
    echo "Error: unsupported architecture: $(uname -m)"
    echo "This installer supports ${ARCH} only."
    exit 1
fi

echo "==> Installing ttyd ${VERSION}"

if [[ -x "$INSTALL_PATH" ]]; then
    INSTALLED_VERSION="$("$INSTALL_PATH" --version 2>/dev/null || true)"

    if [[ "$INSTALLED_VERSION" == *"$VERSION"* ]]; then
        echo "ttyd ${VERSION} is already installed."
        exit 0
    fi

    echo "Existing ttyd installation found:"
    echo "  $INSTALLED_VERSION"
    echo "Replacing it..."
fi

TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

echo "Downloading ttyd ${VERSION}..."

curl -fL \
    "$URL" \
    -o "$TMP_FILE"

chmod +x "$TMP_FILE"

echo "Installing to ${INSTALL_PATH}..."

install -m 0755 "$TMP_FILE" "$INSTALL_PATH"

echo ""
echo "==> ttyd installed successfully"

echo ""
echo "Version:"
"$INSTALL_PATH" --version

echo ""
echo "Location:"
echo "$INSTALL_PATH"
