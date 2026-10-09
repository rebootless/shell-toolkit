#!/bin/bash

# ---DOC-START---
# summary: Install firewalld with its GUI configuration tool (firewall-config).
# description: |
#   Installs [firewalld](https://firewalld.org) and `firewall-config`, its
#   GTK graphical configuration tool.
#
#   - Enables and starts the `firewalld` service.
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

echo "==> Installing Firewalld GUI"

echo "Updating package lists..."
apt update -q

echo "Installing firewalld and firewall-config..."
apt install -y firewalld firewall-config

echo "Enabling and starting firewalld service..."
systemctl enable --now firewalld

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    echo "ufw is currently active. Running both ufw and firewalld can cause"
    echo "conflicting rules. Consider disabling ufw:"
    echo "  sudo ufw disable"
fi

echo ""
echo "firewalld and firewall-config installed successfully."
echo "Launch the GUI with:"
echo "  firewall-config"
