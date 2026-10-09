#!/bin/bash

# ---DOC-START---
# summary: Open /etc/apt/sources.list in Nano.
# description: |
#   Opens the main APT sources file in the Nano text editor.
#
#   - Verifies the script is run as root
#   - Verifies that Nano is installed
#   - Verifies that the sources.list file exists
#   - Opens the file in Nano
#
# sudo: true
# interactive: true
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

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

if [[ ! -f /etc/apt/sources.list ]]; then
    echo "File not found: /etc/apt/sources.list"
    exit 1
fi

exec nano /etc/apt/sources.list
