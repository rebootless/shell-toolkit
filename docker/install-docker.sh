#!/bin/bash

# ---DOC-START---
# summary: Install Docker Engine and the Docker Compose plugin.
# description: |
#   Installs [Docker](https://www.docker.com) Engine and the Docker Compose plugin from Docker's official `apt` repository (not the Debian/Ubuntu `docker.io` package); enables and starts the service.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing Docker Engine and Docker Compose plugin (official repo)"

if command -v docker &>/dev/null && apt-cache policy docker-ce 2>/dev/null | grep -q "Installed: [^(]"; then
    echo "Docker CE is already installed, skipping installation..."
else
    . /etc/os-release
    DISTRO_ID="$ID"

    echo "Installing prerequisites..."
    apt update -q
    apt install -y ca-certificates curl

    echo "Adding Docker's official GPG key..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo "Adding Docker's official apt repository..."
    ARCH="$(dpkg --print-architecture)"
    CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
    cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DISTRO_ID} ${CODENAME} stable
EOF

    echo "Installing Docker Engine and Docker Compose plugin..."
    apt update -q
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

echo "Enabling and starting Docker service..."
systemctl enable --now docker

echo "Verifying installation..."
docker --version
docker compose version

echo ""
echo "Docker and Docker Compose installed successfully."
