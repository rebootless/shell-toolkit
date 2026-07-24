#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "Installing git-filter-repo via pipx..."

if pipx list 2>/dev/null | grep -q "^package git-filter-repo "; then
    echo "git-filter-repo already installed"
else
    pipx install git-filter-repo
    echo "git-filter-repo installed"
fi
