#!/bin/bash

# ---DOC-START---
# summary: Add an existing user to the sudo group.
# description: |
#   Adds an existing local user to the sudo group.
#
#   - Usage: `sudo ./grant-sudo.sh [username]`
#
#   Safe to re-run — users already in the sudo group are skipped.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

usage() {
    echo "Usage: $0 [username]"
}

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

USER_NAME="${1:-${SUDO_USER:-}}"

if [[ -z "$USER_NAME" ]]; then
    usage
    exit 1
fi

USERNAME="$USER_NAME"

echo "==> Grant sudo access"

if ! dpkg -s sudo >/dev/null 2>&1; then
    echo "sudo package is not installed."
    echo "Install sudo first."
    exit 1
fi

if ! getent group sudo >/dev/null 2>&1; then
    echo "sudo group does not exist."
    echo "Install sudo first."
    exit 1
fi

if ! id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' does not exist."
    exit 1
fi

if getent group sudo | grep -qw "$USERNAME"; then
    echo "User '$USERNAME' is already a member of the sudo group."
    exit 0
fi

echo "Adding '$USERNAME' to sudo group..."
usermod -aG sudo "$USERNAME"

echo ""
echo "User '$USERNAME' added to the sudo group."
echo "The user must log out and log back in for the new group membership to take effect."
