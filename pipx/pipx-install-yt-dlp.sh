#!/bin/bash

# ---DOC-START---
# summary: Install yt-dlp via pipx.
# description: |
#   Installs [yt-dlp](https://github.com/yt-dlp/yt-dlp).
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "Installing yt-dlp via pipx..."

if pipx list 2>/dev/null | grep -q "yt-dlp"; then
    echo "yt-dlp already installed"
else
    pipx install yt-dlp
    echo "yt-dlp installed"
fi
