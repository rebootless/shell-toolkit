#!/bin/bash

# ---DOC-START---
# summary: Create a new local user.
# description: |
#   Creates a new local user and optionally sets a password.
#
#   - Usage: `./create-user.sh <username> [password]`
#   - Password is optional; omit it to create the user without one.
#
#   Safe to re-run — existing users are skipped.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

usage() {
    echo "Usage: $0 <username> [password]"
}

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
    exit 1
fi

USERNAME="$1"
PASSWORD="${2:-}"

echo "==> Create local user"

if [[ -z "$USERNAME" ]]; then
    echo "Username cannot be empty."
    exit 1
fi

# chpasswd uses "user:password"
if [[ "$PASSWORD" == *:* ]]; then
    echo "Password must not contain ':'."
    exit 1
fi

if id "$USERNAME" &>/dev/null; then
    echo "User '$USERNAME' already exists."
    exit 0
fi

echo "Creating user '$USERNAME'..."
adduser --disabled-password --gecos "" "$USERNAME"

if [[ -n "$PASSWORD" ]]; then
    printf '%s:%s\n' "$USERNAME" "$PASSWORD" | chpasswd
    echo "Password set."
else
    echo "No password specified."
fi

echo
echo "User '$USERNAME' created successfully."
