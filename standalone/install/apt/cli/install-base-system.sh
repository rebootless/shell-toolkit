#!/bin/bash
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi
echo "==> Installing system and documentation packages"

echo "Updating package lists..."
apt update -q

echo "Installing system and documentation packages..."
apt install -y \
    systemd \
    systemd-timesyncd \
    man-db \
    manpages \
    manpages-dev \
    ca-certificates \
    gnupg

echo ""
echo "System and documentation packages installed successfully."
