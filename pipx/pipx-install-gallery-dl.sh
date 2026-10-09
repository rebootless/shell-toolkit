#!/bin/bash

# ---DOC-START---
# summary: Install gallery-dl via pipx.
# description: |
#   Installs [gallery-dl](https://github.com/mikf/gallery-dl).
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "Installing gallery-dl via pipx..."

if pipx list 2>/dev/null | grep -q "gallery-dl"; then
    echo "gallery-dl already installed"
else
    pipx install gallery-dl
    echo "gallery-dl installed"
fi
