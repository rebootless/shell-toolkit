#!/bin/bash

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "[*] Installing Ansible via pipx..."

if pipx list 2>/dev/null | grep -q "^package ansible "; then
    echo "[i] Existing Ansible installation found, reinstalling..."
    pipx uninstall ansible
fi

pipx install --include-deps ansible

echo "[+] Ansible installed"
