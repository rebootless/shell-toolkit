#!/bin/bash

# ---DOC-START---
# summary: Install VirtualBox and grant vboxusers group membership.
# description: |
#   Installs VirtualBox and adds an existing user to the `vboxusers` group.
#
#   - Runs in order: `install-virtualbox.sh`, `grant-vboxusers.sh`
# sudo: true
# interactive: true
# idempotent: true
# dependencies: install/install-virtualbox.sh, group-management/grant-vboxusers.sh
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR="$(cd "$SCRIPT_DIR/../install" && pwd)"
GROUP_DIR="$(cd "$SCRIPT_DIR/../group-management" && pwd)"

run_scripts() {
    local dir="$1"
    shift
    local scripts=("$@")

    cd "$dir"

    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            echo "Running $script"
            bash "$script"
        else
            echo "Missing $script in $dir"
        fi
    done
}

echo "Running VirtualBox setup..."

run_scripts "$INSTALL_DIR" \
    install-virtualbox.sh

run_scripts "$GROUP_DIR" \
    grant-vboxusers.sh

echo "Done."
