#!/bin/bash

# ---DOC-START---
# summary: Install VHS from the official Charm APT repository.
# description: |
#   Configures the official Charm APT repository and installs VHS.
#
#   - Repository: https://repo.charm.sh/apt/
#   - Install path: `/usr/bin/vhs`
#   - Uses a dedicated APT keyring.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

KEYRING="/etc/apt/keyrings/charm.gpg"
REPO_FILE="/etc/apt/sources.list.d/charm.list"
REPO="deb [signed-by=${KEYRING}] https://repo.charm.sh/apt/ * *"
GPG_URL="https://repo.charm.sh/apt/gpg.key"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing VHS"

echo "Installing dependencies..."

apt-get update -q
apt-get install -y \
    ca-certificates \
    curl \
    gnupg

echo ""
echo "Configuring Charm APT repository..."

install -d -m 0755 /etc/apt/keyrings

TMP_KEY="$(mktemp)"
trap 'rm -f "$TMP_KEY"' EXIT

curl -fsSL "$GPG_URL" -o "$TMP_KEY"

gpg --dearmor \
    --yes \
    -o "$KEYRING" \
    "$TMP_KEY"

chmod 0644 "$KEYRING"

cat > "$REPO_FILE" <<EOF
$REPO
EOF

echo "Updating package lists..."

apt-get update -q

echo "Installing VHS..."

apt-get install -y vhs

echo ""
echo "==> VHS installed successfully"

echo ""
echo "Version:"
vhs --version

echo ""
echo "Location:"
command -v vhs
