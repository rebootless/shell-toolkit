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

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Error: Firewall management tools require root privileges. Please run with sudo.${NC}"
    exit 1
fi

printf "\n${YELLOW}FIREWALL INFORMATION:${NC}\n\n"

if command -v ufw >/dev/null 2>&1; then
    echo -e "${YELLOW}UFW Status:${NC}"
    ufw status verbose
elif command -v firewall-cmd >/dev/null 2>&1; then
    echo -e "${YELLOW}Firewalld Active Zones:${NC}"
    firewall-cmd --get-active-zones
    echo -e "\n${YELLOW}Firewalld Rules (List All):${NC}"
    firewall-cmd --list-all
else
    echo "Firewall (UFW/Firewalld) not installed or active."
fi

echo ""
