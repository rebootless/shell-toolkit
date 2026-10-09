#!/bin/bash

# ---DOC-START---
# summary: Install QEMU/KVM and grant required group memberships.
# description: |
#   Installs QEMU/KVM and adds an existing user to the required virtualization groups.
#
#   - Runs in order: `install-qemu-kvm.sh`, `grant-libvirt.sh`, `grant-kvm.sh`
# sudo: true
# interactive: true
# idempotent: true
# dependencies: install/install-qemu-kvm.sh, group-management/grant-libvirt.sh, group-management/grant-kvm.sh
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

echo "Running KVM/QEMU setup..."

run_scripts "$INSTALL_DIR" \
    install-qemu-kvm.sh

run_scripts "$GROUP_DIR" \
    grant-libvirt.sh \
    grant-kvm.sh

echo "Done."
