#!/bin/bash

# ---DOC-START---
# summary: Recent kernel ring buffer messages (dmesg).
# description: |
#   Read-only status and diagnostic script — does not modify system configuration.
#
#   - Collects the last 20 lines of `dmesg`.
#
#   > Running as `sudo` is required on systems with `kernel.dmesg_restrict` enabled.
# sudo: true
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

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Running as non-root. dmesg output may be restricted.${NC}"
fi

printf "\n${YELLOW}KERNEL LOG (dmesg, last 20 lines):${NC}\n\n"

dmesg 2>/dev/null | tail -n 20 || echo "Permission denied or unavailable."

echo ""
