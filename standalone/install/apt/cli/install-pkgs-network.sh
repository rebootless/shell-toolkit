#!/bin/bash

# ---DOC-START---
# summary: Install network and Bluetooth management tools.
# description: |
#   Installs `network-manager`, `network-manager-gnome`, `blueman`, `bluez`,
#   `bluez-tools`, `firewalld`, `firewall-config`, `ethtool`.
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

echo "==> Installing network and Bluetooth tools"

echo "Updating package lists..."
apt update -q

echo "Installing network and Bluetooth tools..."
apt install -y \
    network-manager \
    network-manager-gnome \
    blueman \
    bluez \
    bluez-tools \
    firewalld \
    firewall-config \
    ethtool

echo ""
echo "Network and Bluetooth tools installed successfully."
