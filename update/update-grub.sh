#!/bin/bash

# ---DOC-START---
# summary: Update the GRUB bootloader configuration.
# description: |
#   Regenerates the GRUB configuration file by detecting installed kernels
#   and operating systems. Useful after kernel updates, bootloader changes,
#   or modifying GRUB settings.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Updating GRUB configuration..."

update-grub

echo ""
echo "GRUB configuration updated successfully."
