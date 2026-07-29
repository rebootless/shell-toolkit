#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing QEMU/KVM virtualization stack"

echo "Updating package lists..."
apt update -q

echo "Installing packages..."
apt install -y \
    qemu-system-x86 \
    qemu-utils \
    qemu-block-extra \
    ovmf \
    seabios \
    libvirt-daemon \
    libvirt-daemon-system \
    libvirt-clients \
    virt-manager \
    virtinst \
    bridge-utils \
    dnsmasq-base \
    swtpm \
    swtpm-tools \
    spice-vdagent \
    cloud-image-utils \
    genisoimage \
    virt-viewer \
    libosinfo-bin \
    osinfo-db-tools

echo "Enabling and starting libvirtd..."
systemctl enable --now libvirtd

echo ""
echo "QEMU/KVM virtualization stack installed successfully."

echo ""
echo "Launch Virt-Manager with:"
echo "  virt-manager"
echo "Manage virtual machines from the CLI with:"
echo "  virsh"
echo "Verify the daemon status with:"
echo "  systemctl status libvirtd"
