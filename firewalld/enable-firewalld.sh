#!/bin/bash

# ---DOC-START---
# summary: Enable Firewalld.
# description: |
#   Enables and starts **Firewalld**.
#
#   - Enables the Firewalld service to start at boot.
#   - Starts the Firewalld service immediately.
#   - Note: if UFW is active, it should be disabled to avoid conflicting
#     netfilter rules; this script does not do that automatically.
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
    echo "Firewalld is not installed."
    exit 1
fi

echo "Enabling and starting Firewalld..."
systemctl enable --now firewalld

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    echo "UFW is currently active. Running both UFW and Firewalld can cause"
    echo "conflicting rules. Consider disabling UFW:"
    echo "  sudo ufw disable"
fi

echo "Firewalld has been enabled."
