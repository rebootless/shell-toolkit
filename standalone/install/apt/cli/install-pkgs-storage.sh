#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing disk, filesystem, and removable media tools"

echo "Updating package lists..."
apt update -q

echo "Installing disk, filesystem, and removable media tools..."
apt install -y \
    udisks2 \
    gvfs \
    gvfs-backends \
    gvfs-fuse \
    gnome-disk-utility \
    e2fsprogs \
    btrfs-progs \
    xfsprogs \
    dosfstools \
    ntfs-3g \
    smartmontools \
    nvme-cli

echo ""
echo "Disk, filesystem, and removable media tools installed successfully."
