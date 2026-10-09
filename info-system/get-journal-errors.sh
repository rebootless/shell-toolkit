#!/bin/bash

# ---DOC-START---
# summary: Recent critical/error entries from the system journal.
# description: |
#   Read-only status and diagnostic script.
#
#   - Collects the last 15 critical/error priority events via `journalctl -p 3 -xb`.
#
#   > Running as `sudo` is required to read full system journal logs.
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
    echo -e "${YELLOW}Warning: Running as non-root. Journalctl logs might be restricted.${NC}"
fi

printf "\n${YELLOW}JOURNAL ERRORS (LAST 15 CRITICAL/ERROR EVENTS):${NC}\n\n"

if command -v journalctl >/dev/null 2>&1; then
    journalctl -p 3 -xb -n 15 --no-pager 2>/dev/null || echo "Permission denied to read journal."
else
    echo "journalctl not found."
fi

echo ""
