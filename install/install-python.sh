#!/bin/bash

# ---DOC-START---
# summary: Install the Python development environment.
# description: |
#   Installs `python3`, `python3-pip`, `python3-venv`, `pipx`.
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

echo "==> Installing Python development environment"

echo "Updating package lists..."
apt update -q

echo "Installing Python development environment..."
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    pipx

echo ""
echo "Python development environment installed successfully."
