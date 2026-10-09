#!/bin/bash

# ---DOC-START---
# summary: Install package sets for the GTK/Xfce stack.
# description: |
#   Installs predefined package sets for the GTK/Xfce stack.
#
#   Run without arguments to list the available sets and their packages.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

# name|packages|description
REGISTRY='file-manager|thunar thunar-archive-plugin thunar-volman xarchiver|Thunar file manager and archive support
gvfs|gvfs gvfs-backends gvfs-fuse|GVfs virtual filesystems'

usage() {
    echo "Usage: ${0##*/} <name>..."
    echo "       ${0##*/} --help"
    echo
    echo "Install package sets for the GTK/Xfce stack (one apt transaction)."
    echo
    echo "Available sets:"
    local n p d
    while IFS='|' read -r n p d; do
        printf '  %-16s %s\n' "$n" "$d"
        echo "$p" | fold -s -w 64 | sed 's/^/                     /'
    done <<< "$REGISTRY"
}

find_entry() {
    local n d
    while IFS='|' read -r n pkgs d; do
        [[ $n == "$1" ]] && return 0
    done <<< "$REGISTRY"
    return 1
}

if [[ $# -eq 0 ]]; then
    usage
    exit 0
fi

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
esac

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

packages=()
for name in "$@"; do
    if ! find_entry "$name"; then
        echo "Unknown name: $name (run without arguments to list names)" >&2
        exit 1
    fi
    read -ra items <<< "$pkgs"
    packages+=("${items[@]}")
done

echo "==> Installing: $*"

echo "Updating package lists..."
apt update -q

echo "Installing packages..."
apt install -y "${packages[@]}"

echo ""
echo "Installed successfully."
