#!/bin/bash

# ---DOC-START---
# summary: Install flatpak, add the Flathub repository.
# description: |
#   Installs `flatpak`, adds the [Flathub](https://flathub.org)
#   repository and configures Flatpak environment variables.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(eval echo "~$REAL_USER")"

echo "==> Installing Flatpak"

echo "Installing Flatpak..."
sudo apt update
sudo apt install -y flatpak

echo "Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "Configuring Flatpak environment..."

ENV_DIR="$REAL_HOME/.config/environment.d"
ENV_FILE="$ENV_DIR/flatpak.conf"

mkdir -p "$ENV_DIR"

cat > "$ENV_FILE" <<EOF
XDG_DATA_DIRS=/var/lib/flatpak/exports/share:$REAL_HOME/.local/share/flatpak/exports/share:/usr/local/share:/usr/share
EOF

chown "$REAL_USER:$REAL_USER" "$ENV_FILE"

# echo "KDE Discover Flatpak backend..."
# if dpkg -s plasma-discover >/dev/null 2>&1; then
#     sudo apt install -y plasma-discover-backend-flatpak
#     echo "Discover Flatpak support enabled"
# else
#     echo "KDE Discover not installed, skipping integration..."
# fi

echo ""
echo "Flatpak setup complete"
