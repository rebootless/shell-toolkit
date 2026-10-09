#!/bin/bash

# ---DOC-START---
# summary: Install GUI package sets that work in any desktop environment.
# description: |
#   Installs predefined GUI package sets that are not tied to a specific desktop environment.
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
REGISTRY='audio|pipewire pipewire-pulse wireplumber alsa-utils|PipeWire/WirePlumber audio stack
graphics|libegl1 libgl1 libgles2 mesa-utils|GL libraries and diagnostics
appimage|fuse3 libfuse2t64 libnss3|Runtime libraries for AppImage and Electron
xdg|xdg-utils xdg-user-dirs|XDG utilities and user directories
accessibility|speech-dispatcher|Speech dispatcher
udisks|udisks2 gnome-disk-utility|Removable media daemon and disk utility
network-gui|network-manager-gnome blueman firewall-config|Network, Bluetooth and firewall GUIs
apps-media|vlc obs-studio nsxiv|Media applications
apps-graphics|gimp inkscape blender flameshot|Graphics applications
apps-net|firefox-esr qbittorrent remmina|Network applications'

usage() {
    echo "Usage: ${0##*/} <name>..."
    echo "       ${0##*/} --help"
    echo
    echo "Install GUI package sets for any desktop environment (one apt transaction)."
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
