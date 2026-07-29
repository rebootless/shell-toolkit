#!/bin/bash

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
