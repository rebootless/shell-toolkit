#!/bin/bash

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
