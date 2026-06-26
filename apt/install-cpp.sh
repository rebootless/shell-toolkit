#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "[*] Updating package lists..."
apt update

echo "[*] Installing C/C++ development environment..."
apt install -y \
    build-essential \
    gcc \
    g++ \
    clang \
    cmake \
    ninja-build \
    make \
    gdb \
    lldb \
    binutils \
    pkg-config \
    libstdc++-12-dev

echo "[+] C/C++ development environment installed successfully."
