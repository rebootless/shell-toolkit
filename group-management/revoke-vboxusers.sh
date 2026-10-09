#!/bin/bash

# ---DOC-START---
# summary: Remove an existing user from the vboxusers group.
# description: |
#   Removes an existing local user from the vboxusers group used by VirtualBox
#   for accessing USB devices and other VirtualBox features without root.
#
#   - Usage: `sudo ./revoke-vboxusers.sh [username]`
#
#   Safe to re-run — users not in the vboxusers group are skipped.
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

echo "==> Revoke vboxusers access"

if ! getent group vboxusers >/dev/null 2>&1; then
    echo "vboxusers group does not exist."
    echo "Install VirtualBox first."
    exit 1
fi

if ! id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' does not exist."
    exit 1
fi

if ! getent group vboxusers | grep -qw "$USERNAME"; then
    echo "User '$USERNAME' is not a member of the vboxusers group."
    exit 0
fi

echo "Removing '$USERNAME' from vboxusers group..."
gpasswd -d "$USERNAME" vboxusers

echo ""
echo "User '$USERNAME' removed from the vboxusers group."
echo "The user must log out and log back in for the group membership change to take effect."
