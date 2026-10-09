#!/bin/bash

# ---DOC-START---
# summary: Install Firefox from the distribution repositories.
# description: |
#   Installs [Firefox](https://www.mozilla.org/firefox/) via apt.
#
#   - Uses the `firefox` package where available (Ubuntu's apt repos install
#     the Snap transitional package on stock Ubuntu; Debian ships a real deb).
#   - Falls back to `firefox-esr`, the package name used on Debian stable
#     when the plain `firefox` package does not exist in the configured repos.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing Firefox"

if command -v firefox >/dev/null 2>&1; then
    echo "Firefox is already installed, skipping..."
    exit 0
fi

echo "Updating package lists..."
apt update -q

if apt-cache show firefox >/dev/null 2>&1; then
    PKG="firefox"
elif apt-cache show firefox-esr >/dev/null 2>&1; then
    PKG="firefox-esr"
else
    echo "No Firefox package (firefox / firefox-esr) found in configured repositories."
    exit 1
fi

echo "Installing Firefox (${PKG})..."
apt install -y "$PKG"

echo ""
echo "Firefox installed successfully."
