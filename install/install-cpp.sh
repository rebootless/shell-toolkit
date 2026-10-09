#!/bin/bash

# ---DOC-START---
# summary: Install the C and C++ development environment.
# description: |
#   Installs `build-essential`, `gcc`, `g++`, `clang`, `cmake`, `ninja-build`, `gdb`, `lldb`, `binutils`, `pkg-config`.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing C/C++ development environment"

echo "Updating package lists..."
apt update -q

echo "Installing C/C++ development environment..."
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
    pkg-config

echo ""
echo "C/C++ development environment installed successfully."
