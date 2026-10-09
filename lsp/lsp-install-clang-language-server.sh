#!/bin/bash

# ---DOC-START---
# summary: Install clangd (LLVM C/C++ language server) for editor/IDE LSP integration.
# description: |
#   Installs the LLVM Clang Language Server (`clangd`) from the Debian repositories.
#
#   - Installs via `apt`
#   - Provides LSP support for C, C++, Objective-C and Objective-C++
#   - Idempotent — skips installation if `clangd` is already available
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

echo "==> Installing Clangd"

if command -v clangd >/dev/null 2>&1; then
    echo "clangd already installed, skipping..."
    exit 0
fi

apt-get update
apt-get install -y clangd

echo ""
echo "clangd installed successfully."
