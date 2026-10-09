#!/bin/bash

# ---DOC-START---
# summary: USB device inventory.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Collects the USB device list via `lsusb`.
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED='' YELLOW='' NC=''
fi

trap 'echo -e "\n${RED}Script interrupted${NC}"; exit 130' INT TERM

printf "\n${YELLOW}USB DEVICES:${NC}\n\n"

if command -v lsusb >/dev/null 2>&1; then
    lsusb
else
    echo "lsusb not installed."
fi

echo ""
