#!/bin/bash

# ---DOC-START---
# summary: Currently logged-in users and recent login history.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Collects currently logged-in users (`w`) and the last 10 logins (`last`).
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

missing=()
for cmd in w last; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing core commands: ${missing[*]}${NC}"
    exit 1
fi

printf "\n${YELLOW}LOGGED-IN USERS:${NC}\n\n"

echo -e "${YELLOW}Currently Logged-in Users (w):${NC}"
w

echo -e "\n${YELLOW}Last Logins (last -n 10):${NC}"
last -n 10

echo ""
