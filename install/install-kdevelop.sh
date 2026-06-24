#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "[*] Checking root privileges..."
if [[ $EUID -ne 0 ]]; then
    echo "[!] Run as root (sudo)."
    exit 1
fi

echo "[*] Updating package lists..."
apt update

echo "[*] Installing core build tools..."
apt install -y \
    build-essential \
    gcc \
    g++ \
    clang \
    clang++ \
    cmake \
    ninja-build \
    make \
    gdb \
    lldb \
    binutils \
    pkg-config \
    libstdc++-12-dev || true

echo "[*] Installing Python stack..."
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    pipx

echo "[*] Installing Git..."
apt install -y git

echo "[*] Installing KDevelop ecosystem..."
apt install -y \
    kdevelop \
    kdevelop-python \
    kdevelop-php \
    kdevplatform-dev \
    kdevelop-plugins || true

echo "[*] Installing PHP stack for KDevelop PHP support..."
apt install -y \
    php \
    php-cli \
    php-common \
    php-mbstring \
    php-xml \
    php-curl \
    php-zip \
    php-intl \
    php-mysql \
    php-sqlite3 \
    php-gd \
    php-xdebug || true

echo "[*] Cleaning up..."
apt autoremove -y
apt clean

echo "[+] Development environment installed successfully."