#!/bin/bash

# ---DOC-START---
# summary: Remove Firewalld.
# description: |
#   Completely removes **Firewalld**.
#
#   - Removes the Firewalld package
#   - Removes automatically installed unused dependencies
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "Firewalld is not installed. Nothing to do."
    exit 0
fi

echo "Removing Firewalld..."
apt-get remove -y firewalld

echo "Removing unused dependencies..."
apt-get autoremove -y

echo "Firewalld has been removed."
