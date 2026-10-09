#!/bin/bash

# ---DOC-START---
# summary: Install VeraCrypt CLI from the official PPA.
# description: |
#   Installs [VeraCrypt](https://www.veracrypt.fr) CLI (Console Only)
#   from the official PPA.
#   - Note: **the CLI and GUI VeraCrypt packages are mutually exclusive.** Install only one of them.
# sudo: true
# interactive: false
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

echo "==> VeraCrypt CLI Setup"

echo "Updating package lists..."
apt update -q

echo "Installing dependencies..."
apt install -y wget curl

echo "Determining latest VeraCrypt version..."
DOWNLOAD_PAGE="$(curl -fsSL https://veracrypt.io/en/Downloads.html)"
VER="$(echo "$DOWNLOAD_PAGE" \
    | grep -oP 'veracrypt-\K[0-9.]+(?=-Debian-[0-9]+-amd64\.deb)' \
    | head -n1)"
if [[ -z "$VER" ]]; then
    echo "Failed to determine latest VeraCrypt version."
    exit 1
fi
echo "Latest version: ${VER}"

BASE_URL="https://launchpad.net/veracrypt/trunk/${VER}/+download"
DEBIAN_MAJOR="$(cut -d '.' -f1 /etc/debian_version)"

echo "Searching for compatible Debian package..."
FOUND=0
for ((VER_DEB=DEBIAN_MAJOR; VER_DEB>=11; VER_DEB--)); do
    TEST_PKG="veracrypt-console-${VER}-Debian-${VER_DEB}-amd64.deb"
    if wget --spider --timeout=3 --tries=1 -4 -q "${BASE_URL}/${TEST_PKG}"; then
        PKG_DEBIAN_VERSION="$VER_DEB"
        FOUND=1
        break
    fi
done
if [[ $FOUND -eq 0 ]]; then
    echo "No compatible VeraCrypt package found."
    exit 1
fi
echo "Using Debian ${PKG_DEBIAN_VERSION} package."

TARGET_PKG="veracrypt-console-${VER}-Debian-${PKG_DEBIAN_VERSION}-amd64.deb"
echo "Downloading VeraCrypt Console package..."
wget -q --show-progress -O "/tmp/${TARGET_PKG}" "${BASE_URL}/${TARGET_PKG}"

echo "Installing VeraCrypt..."
apt install -y "/tmp/${TARGET_PKG}"

echo "Cleaning up..."
rm -f "/tmp/${TARGET_PKG}"

echo ""
echo "==> Summary"

echo ""
echo "VeraCrypt (cli) installed successfully."

echo ""
if [[ "$PKG_DEBIAN_VERSION" != "$DEBIAN_MAJOR" ]]; then
    echo "No package for Debian ${DEBIAN_MAJOR} was available."
    echo "Installed package built for Debian ${PKG_DEBIAN_VERSION}."
fi

echo ""
echo "VeraCrypt uses FUSE. If mounting volumes fails,"
echo "ensure that the fuse kernel module is loaded:"
echo "  modprobe fuse"
