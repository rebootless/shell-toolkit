#!/bin/bash

# ---DOC-START---
# summary: Disable and uninstall Firewalld.
# description: |
#   Disables the Firewalld service and removes the package.
#
#   - Runs in order: `disable-firewalld.sh`, `remove-firewalld.sh`
# sudo: true
# interactive: false
# idempotent: true
# dependencies: firewalld/disable-firewalld.sh, firewalld/remove-firewalld.sh
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

echo "Running Firewalld uninstallation..."

run_scripts "$FIREWALL_DIR" \
    disable-firewalld.sh \
    remove-firewalld.sh

echo "Done."
