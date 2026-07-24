#!/bin/bash

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
