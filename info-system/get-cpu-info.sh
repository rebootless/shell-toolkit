#!/bin/bash

# ---DOC-START---
# summary: CPU architecture, model, core, and thread information.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Collects architecture, model name, core/thread counts via `lscpu`.
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

command -v lscpu >/dev/null 2>&1 || { echo -e "${RED}Missing command: lscpu${NC}"; exit 1; }

printf "\n${YELLOW}CPU INFORMATION:${NC}\n\n"

lscpu | grep -E "^(Architecture|Model name|CPU\(s\)|Thread\(s\) per core|Core\(s\) per socket)"

echo ""
