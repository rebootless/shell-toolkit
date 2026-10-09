#!/bin/bash

# ---DOC-START---
# summary: Install ranger from the distribution repositories.
# description: |
#   Installs [ranger](https://github.com/ranger/ranger) via apt.
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

echo "==> Installing ranger"

if command -v ranger >/dev/null 2>&1; then
    echo "ranger is already installed, skipping..."
    exit 0
fi

echo "Updating package lists..."
apt update -q

echo "Installing ranger..."
apt install -y ranger

echo ""
echo "ranger installed successfully."
