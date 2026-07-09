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

missing=()
for cmd in ip ss; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing core commands: ${missing[*]}${NC}"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Running as non-root. Process names in 'ss' and iptables will be hidden.${NC}\n"
fi

printf "\n${YELLOW}NETWORK INFORMATION:${NC}\n\n"

echo -e "${YELLOW}Network Interfaces:${NC}"
ip -br a

echo -e "\n${YELLOW}Routing Table:${NC}"
ip route

echo -e "\n${YELLOW}Open Listening Ports (ss -tulpn):${NC}"
ss -tulpn 2>/dev/null || true

echo -e "\n${YELLOW}DNS Resolvers (/etc/resolv.conf):${NC}"
grep -v '^#' /etc/resolv.conf | grep . || true

echo -e "\n${YELLOW}Hosts File (/etc/hosts):${NC}"
cat /etc/hosts 2>/dev/null || true

echo -e "\n${YELLOW}Iptables Rules (iptables-save):${NC}"
if command -v iptables-save >/dev/null 2>&1; then
    iptables-save 2>/dev/null | head -n 30 || echo "Run as root to view iptables."
else
    echo "iptables-save not installed."
fi

echo ""
