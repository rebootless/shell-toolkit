#!/bin/bash
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing networking tools"

echo "Updating package lists..."
apt update -q

echo "Installing networking tools..."
apt install -y \
    openssh-client \
    network-manager \
    iproute2 \
    iputils-ping \
    dnsutils \
    net-tools \
    traceroute \
    tcpdump \
    nmap

echo ""
echo "Networking tools installed successfully."
