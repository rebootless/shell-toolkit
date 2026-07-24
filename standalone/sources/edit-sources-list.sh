#!/bin/bash

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
