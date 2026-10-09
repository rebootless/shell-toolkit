#!/bin/bash

# ---DOC-START---
# summary: Install git-filter-repo via pipx.
# description: |
#   Installs [git-filter-repo](https://github.com/newren/git-filter-repo).
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "Installing git-filter-repo via pipx..."

if pipx list 2>/dev/null | grep -q "^package git-filter-repo "; then
    echo "git-filter-repo already installed"
else
    pipx install git-filter-repo
    echo "git-filter-repo installed"
fi
