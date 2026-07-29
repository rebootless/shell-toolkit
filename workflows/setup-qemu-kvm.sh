#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR="$(cd "$SCRIPT_DIR/../standalone/install/apt/cli" && pwd)"
GROUP_DIR="$(cd "$SCRIPT_DIR/../standalone/group-management" && pwd)"

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

echo "Running KVM/QEMU setup..."

run_scripts "$INSTALL_DIR" \
    install-qemu-kvm.sh

run_scripts "$GROUP_DIR" \
    grant-libvirt.sh \
    grant-kvm.sh

echo "Done."
