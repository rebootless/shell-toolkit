#!/bin/bash

# ---DOC-START---
# summary: Open all .sources files in /etc/apt/sources.list.d/.
# description: |
#   Opens every APT source file with the .sources extension found in
#   /etc/apt/sources.list.d/ using the Nano text editor.
#
#   - Verifies the script is run as root
#   - Verifies that Nano is installed
#   - Verifies that at least one .sources file exists
#   - Opens all matching files in Nano
#
# sudo: true
# interactive: true
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
shopt -s nullglob

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

if ! command -v nano >/dev/null 2>&1; then
    echo "nano is not installed."
    echo "Install it with:"
    echo "  apt-get install nano"
    exit 1
fi

files=(/etc/apt/sources.list.d/*.sources)

if [[ ${#files[@]} -eq 0 ]]; then
    echo "No .sources files found in /etc/apt/sources.list.d/"
    exit 1
fi

exec nano "${files[@]}"
