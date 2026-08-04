#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing base system and CLI utilities"

echo "Updating package lists..."
apt update -q

echo "Installing base system and CLI utilities..."
apt install -y \
    sudo \
    git \
    ranger \
    htop \
    tree \
    curl \
    wget \
    unzip \
    zip \
    p7zip-full \
    rsync \
    less \
    nano \
    ripgrep \
    fd-find \
    fzf \
    jq \
    bc \
    file \
    tar \
    xdg-user-dirs \
    zoxide \
    bash-completion \
    pciutils \
    usbutils \
    xdg-utils \
    acl

echo ""
echo "Base system and CLI utilities installed successfully."
