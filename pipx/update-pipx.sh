#!/bin/bash

# ---DOC-START---
# summary: Upgrades all Python packages installed via pipx.
# description: |
#   Runs `pipx upgrade-all` to upgrade every application installed
#   through pipx to its latest available version.
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if ! command -v pipx >/dev/null 2>&1; then
    echo "pipx is not installed, skipping..."
    exit 0
fi

echo "==> Updating pipx packages"
pipx upgrade-all
printf '\n'
echo "pipx packages upgraded."

echo ""
echo "pipx packages are up to date."
