#!/bin/bash
# ---DOC-START---
# summary: Install the ProtonVPN from the official Proton apt repository.
# description: |
#   Installs the [ProtonVPN](https://protonvpn.com) from the official Proton apt repository.
# sudo: true
# interactive: true
# idempotent: mostly
# dependencies: none
# ---DOC-END---
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing ProtonVPN"

BASE_URL="https://repo.protonvpn.com/debian/dists/stable/main/binary-all"

echo "Detecting latest Proton VPN repository package..."
PKG="$(
    wget -qO- "${BASE_URL}/" \
        | grep -oE 'protonvpn-stable-release_[0-9.]+_all\.deb' \
        | sort -V \
        | tail -n1
)"

if [[ -z "$PKG" ]]; then
    echo "Could not determine the latest Proton VPN repository package."
    exit 1
fi

# The bootstrap repository package version is resolved dynamically.
# Because of that, this initial .deb is installed without a pinned SHA256.
# Once the repository is installed, all subsequent packages are verified
# by apt against Proton's signed repository metadata.
echo "Downloading ${PKG}..."
wget -O "${PKG}" "${BASE_URL}/${PKG}"

echo "Installing Proton VPN repository..."
dpkg -i "./${PKG}"

echo "Updating package lists..."
apt update

echo "Installing Proton VPN..."
apt install -y proton-vpn-gnome-desktop

echo ""
echo "Proton VPN installation completed."

echo ""
echo "Log out and log back into your session"
echo "(or reboot) before launching Proton VPN for the first time."
