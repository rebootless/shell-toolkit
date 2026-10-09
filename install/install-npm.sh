#!/bin/bash

# ---DOC-START---
# summary: Install Node.js and npm.
# description: |
#   Installs `nodejs`, `npm`.
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

echo "==> Installing Node.js + npm"

echo "Updating package lists..."
apt update -q

echo "Installing Node.js + npm..."
apt install -y nodejs npm

echo ""
echo "Node.js + npm installed successfully."
