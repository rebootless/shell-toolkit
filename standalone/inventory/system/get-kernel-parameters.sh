#!/bin/bash

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

command -v sysctl >/dev/null 2>&1 || { echo -e "${RED}Missing command: sysctl${NC}"; exit 1; }

printf "\n${YELLOW}KERNEL PARAMETERS (sysctl):${NC}\n\n"

sysctl -a 2>/dev/null | head -n 20
echo "(... output truncated for readability ...)"

echo ""
