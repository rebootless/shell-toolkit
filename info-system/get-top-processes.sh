#!/bin/bash

# ---DOC-START---
# summary: Top 10 processes by CPU usage.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Collects the top 10 processes by CPU usage via `ps aux --sort=-%cpu`.
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

command -v ps >/dev/null 2>&1 || { echo -e "${RED}Missing command: ps${NC}"; exit 1; }

printf "\n${YELLOW}TOP PROCESSES (BY CPU):${NC}\n\n"

ps aux --sort=-%cpu | head -n 11

echo ""
