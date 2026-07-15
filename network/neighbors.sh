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

command -v ip >/dev/null 2>&1 || { echo -e "${RED}Missing command: ip${NC}"; exit 1; }

printf "\n${YELLOW}=== ARP TABLE (IPv4 Neighbors) ===${NC}\n"
ip -4 neighbor show 2>/dev/null || echo "No IPv4 neighbors found."

printf "\n${YELLOW}=== IPv6 NEIGHBOR CACHE ===${NC}\n"
ip -6 neighbor show 2>/dev/null || echo "No IPv6 neighbors found."

echo ""
