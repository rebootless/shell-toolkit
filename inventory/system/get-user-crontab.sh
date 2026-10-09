#!/bin/bash

# ---DOC-START---
# summary: Current user's crontab entries.
# description: |
#   Read-only status and diagnostic script.
#
#   - Collects the crontab entries for the current user via `crontab -l`.
#
#   > Running as `sudo` reads root's crontab instead of the invoking user's.
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

printf "\n${YELLOW}USER CRONTAB:${NC}\n\n"

if command -v crontab >/dev/null 2>&1; then
    crontab -l 2>/dev/null || echo "No crontab for current user or permission denied."
else
    echo "crontab not installed."
fi

echo ""
