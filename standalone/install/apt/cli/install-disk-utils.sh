#!/bin/bash
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing disk and hardware utilities"

echo "Updating package lists..."
apt update -q

echo "Installing disk and hardware utilities..."
apt install -y \
    parted \
    e2fsprogs \
    dosfstools \
    ntfs-3g \
    exfatprogs \
    smartmontools \
    nvme-cli \
    usbutils \
    pciutils \
    udisks2

echo ""
echo "Disk and hardware utilities installed successfully."
