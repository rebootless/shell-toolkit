#!/bin/bash

# ---DOC-START---
# summary: Non-system local user accounts from /etc/passwd.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Lists local users with UID >= 1000 (excluding `nobody`) from `/etc/passwd`.
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

command -v awk >/dev/null 2>&1 || { echo -e "${RED}Missing command: awk${NC}"; exit 1; }

printf "\n${YELLOW}LOCAL USERS:${NC}\n\n"

awk -F: '($3 >= 1000 && $3 != 65534) {print $1" (UID: "$3")"}' /etc/passwd

echo ""
