#!/bin/bash

# ---DOC-START---
# summary: Disable Firewalld.
# description: |
#   Stops the **Firewalld** service and disables it from starting at boot.
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

echo "Stopping Firewalld..."
systemctl stop firewalld || true

echo "Disabling Firewalld..."
systemctl disable firewalld || true

echo "Firewalld has been disabled."
