#!/bin/bash

# ---DOC-START---
# summary: Install git from the distribution repositories.
# description: |
#   Installs [git](https://git-scm.com) via apt.
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

echo "==> Installing git"

if command -v git >/dev/null 2>&1; then
    echo "git is already installed, skipping..."
    exit 0
fi

echo "Updating package lists..."
apt update -q

echo "Installing git..."
apt install -y git

echo ""
echo "git installed successfully."
