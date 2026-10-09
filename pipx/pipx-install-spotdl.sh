#!/bin/bash

# ---DOC-START---
# summary: Install spotdl via pipx.
# description: |
#   Installs [spotdl](https://github.com/spotDL/spotify-downloader).
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "Installing spotdl via pipx..."

if pipx list 2>/dev/null | grep -q "spotdl"; then
    echo "spotdl already installed"
else
    pipx install spotdl
    echo "spotdl installed"
fi
