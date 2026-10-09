#!/bin/bash

# ---DOC-START---
# summary: System memory usage (RAM and swap).
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Collects RAM and swap usage via `free -h`.
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

command -v free >/dev/null 2>&1 || { echo -e "${RED}Missing command: free${NC}"; exit 1; }

printf "\n${YELLOW}MEMORY INFORMATION:${NC}\n\n"

free -h

echo ""
