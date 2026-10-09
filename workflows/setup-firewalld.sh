#!/bin/bash

# ---DOC-START---
# summary: Install and enable Firewalld.
# description: |
#   Installs Firewalld and enables the service.
#
#   - Runs in order: `install-firewalld-cli.sh`, `enable-firewalld.sh`
# sudo: true
# interactive: false
# idempotent: true
# dependencies: firewalld/install-firewalld-cli.sh, firewalld/enable-firewalld.sh
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR="$(cd "$SCRIPT_DIR/../firewalld" && pwd)"
FIREWALL_DIR="$(cd "$SCRIPT_DIR/../firewalld" && pwd)"

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

echo "Running Firewalld setup..."

run_scripts "$INSTALL_DIR" \
    install-firewalld-cli.sh

run_scripts "$FIREWALL_DIR" \
    enable-firewalld.sh

echo "Done."
