#!/bin/bash

# ---DOC-START---
# summary: Install firewalld.
# description: |
#   Installs [firewalld](https://firewalld.org).
#
#   - Note: if `ufw` is active, it should be disabled to avoid conflicting
#     netfilter rules; this script does not do that automatically.
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

echo "==> Installing Firewalld CLI"

echo "Updating package lists..."
apt update -q

echo "Installing firewalld..."
apt install -y firewalld

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    echo "ufw is currently active. Running both ufw and firewalld can cause"
    echo "conflicting rules. Consider disabling ufw:"
    echo "  sudo ufw disable"
fi

echo ""
echo "firewalld installed successfully."
echo "Enable with:"
echo "  systemctl enable --now firewalld"
echo "Launch the CLI with:"
echo "  firewall-cmd"
