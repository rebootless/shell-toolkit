#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' NC=''
fi

trap 'echo -e "\n${RED}Script interrupted${NC}"; exit 130' INT TERM

command -v curl >/dev/null 2>&1 || { echo -e "${RED}Missing command: curl${NC}"; exit 1; }

printf "\n${YELLOW}=== PUBLIC IP ADDRESSES ===${NC}\n"

pub_ipv4=$(curl -s --max-time 4 -4 https://api.ipify.org 2>/dev/null || true)
if [[ -z "$pub_ipv4" ]]; then
    pub_ipv4=$(curl -s --max-time 4 -4 https://ifconfig.me 2>/dev/null || echo "Unavailable")
fi

pub_ipv6=$(curl -s --max-time 4 -6 https://api6.ipify.org 2>/dev/null || true)
if [[ -z "$pub_ipv6" ]]; then
    pub_ipv6=$(curl -s --max-time 4 -6 https://ifconfig.co 2>/dev/null || echo "Unavailable")
fi

echo -e "Public IPv4 : ${GREEN}$pub_ipv4${NC}"
echo -e "Public IPv6 : ${GREEN}$pub_ipv6${NC}"
echo ""
