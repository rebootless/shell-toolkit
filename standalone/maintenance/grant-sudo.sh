#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

TARGET_USER="${1:-${SUDO_USER:-}}"

if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
    echo "[!] Invalid target user."
    echo "Usage: $0 <username>"
    exit 1
fi

if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "[!] User does not exist: $TARGET_USER"
    exit 1
fi

echo "[*] Target user: $TARGET_USER"


# 1. Preferred method: add to sudo group
if getent group sudo >/dev/null 2>&1; then
    if id -nG "$TARGET_USER" | grep -qw sudo; then
        echo "[i] User already in 'sudo' group."
    else
        echo "[*] Adding user to 'sudo' group..."
        usermod -aG sudo "$TARGET_USER"
    fi
else
    echo "[i] 'sudo' group not found, skipping group method."
fi


# 2. Fallback: sudoers.d entry (works even without sudo group)
SUDOERS_FILE="/etc/sudoers.d/${TARGET_USER}"

if [[ -f "$SUDOERS_FILE" ]]; then
    echo "[i] sudoers file already exists: $SUDOERS_FILE"
else
    echo "[*] Creating sudoers file..."
    cat > "$SUDOERS_FILE" <<EOF
${TARGET_USER} ALL=(ALL:ALL) ALL
EOF

    chmod 440 "$SUDOERS_FILE"

    # Validate sudoers syntax
    if visudo -cf /etc/sudoers >/dev/null; then
        echo "[+] sudoers syntax OK"
    else
        echo "[!] sudoers syntax error! removing file..."
        rm -f "$SUDOERS_FILE"
        exit 1
    fi
fi

echo
echo "[+] Done."

echo "[i] User groups:"
id "$TARGET_USER"

echo "[i] sudo access check:"
sudo -l -U "$TARGET_USER" || true
