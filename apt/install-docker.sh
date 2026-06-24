#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "[*] Updating package lists..."
apt update

echo "[*] Installing Docker Engine (docker.io) and Docker Compose plugin..."
apt install -y docker.io docker-compose

echo "[*] Enabling and starting Docker service..."
systemctl enable --now docker

echo "[*] Verifying installation..."
docker --version
docker compose version

echo "[+] Docker and Docker Compose installed successfully."
