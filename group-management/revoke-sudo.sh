#!/bin/bash

# ---DOC-START---
# summary: Remove an existing user from the sudo group.
# description: |
#   Removes an existing local user from the sudo group.
#
#   - Usage: `sudo ./revoke-sudo.sh [username]`
#
#   Safe to re-run — users not in the sudo group are skipped.
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

echo "==> Revoke sudo access"

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

if ! getent group sudo | grep -qw "$USERNAME"; then
    echo "User '$USERNAME' is not a member of the sudo group."
    exit 0
fi

echo "Removing '$USERNAME' from sudo group..."
gpasswd -d "$USERNAME" sudo

echo ""
echo "User '$USERNAME' removed from the sudo group."
echo "The user must log out and log back in for the group membership change to take effect."
