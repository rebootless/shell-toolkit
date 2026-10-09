#!/bin/bash

# ---DOC-START---
# summary: Updates the APT package index and upgrades all installed packages.
# description: |
#   Runs `apt-get update` to refresh the package index, then
#   `apt-get upgrade -y` to install all available updates.
# sudo: true
# interactive: false
# idempotent: mostly
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

echo "==> Updating package index"
apt-get update
echo "Package index refreshed."

echo "==> Upgrading installed packages"
apt-get upgrade -y
echo "Packages upgraded."

echo ""
echo "System packages are up to date."
