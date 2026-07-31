#!/bin/bash
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi
echo "==> Installing base shell environment"

echo "Updating package lists..."
apt update -q

echo "Installing base shell environment..."
apt install -y \
    sudo \
    bash \
    bash-completion \
    coreutils \
    findutils \
    grep \
    gawk \
    sed \
    diffutils \
    patch \
    procps \
    psmisc \
    util-linux \
    file \
    which

echo ""
echo "Base shell environment installed successfully."
