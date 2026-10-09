#!/bin/bash

# ---DOC-START---
# summary: Install Ansible via pipx.
# description: |
#   Installs the latest Ansible using pipx with all command-line tools
#   exposed, including ansible-playbook, ansible-galaxy, ansible-vault,
#   ansible-config, ansible-doc, ansible-console, ansible-inventory,
#   ansible-pull, and ansible-test.
#
#   If Ansible is already installed via pipx, it is removed and reinstalled
#   with --include-deps to ensure all CLI tools are available.
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

echo "Installing Ansible via pipx..."

if pipx list 2>/dev/null | grep -q "^package ansible "; then
    echo "Existing Ansible installation found, reinstalling..."
    pipx uninstall ansible
fi

pipx install --include-deps ansible

echo "Ansible installed"
