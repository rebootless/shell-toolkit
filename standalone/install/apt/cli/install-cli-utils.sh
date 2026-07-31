#!/bin/bash
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing CLI productivity utilities"

echo "Updating package lists..."
apt update -q

echo "Installing CLI productivity utilities..."
apt install -y \
    curl \
    wget \
    htop \
    fastfetch \
    less \
    nano \
    tree \
    rsync \
    bc \
    jq \
    ripgrep \
    fzf \
    dos2unix \
    lsof \
    strace

echo ""
echo "CLI productivity utilities installed successfully."
