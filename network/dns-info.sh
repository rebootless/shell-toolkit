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

missing=()
for cmd in cat awk; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing commands: ${missing[*]}${NC}"
    exit 1
fi

printf "\n${YELLOW}=== DNS CONFIGURATION ===${NC}\n"

resolved_used=0
if command -v resolvectl >/dev/null 2>&1; then
    echo -e "${GREEN}Using systemd-resolved (resolvectl):${NC}\n"
    resolvectl status 2>/dev/null || echo "Failed to get resolvectl status."
    resolved_used=1
fi

if [[ $resolved_used -eq 0 || -L /etc/resolv.conf ]]; then
    echo -e "\n${GREEN}Contents of /etc/resolv.conf:${NC}\n"
    if [[ -f /etc/resolv.conf ]]; then
        grep -v '^#' /etc/resolv.conf || echo "No active entries in /etc/resolv.conf"
    else
        echo "/etc/resolv.conf not found."
    fi
fi

printf "\n${YELLOW}=== ACTIVE DNS SERVERS (Parsed) ===${NC}\n"
nameservers=""
[[ -f /etc/resolv.conf ]] && nameservers=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf 2>/dev/null)
if [[ -n "$nameservers" ]]; then
    echo "$nameservers"
else
    echo "None found."
fi

printf "\n${YELLOW}=== SEARCH DOMAINS ===${NC}\n"
search_domains=""
[[ -f /etc/resolv.conf ]] && search_domains=$(awk '/^search/ {for(i=2;i<=NF;i++) print $i}' /etc/resolv.conf 2>/dev/null)
if [[ -n "$search_domains" ]]; then
    echo "$search_domains"
else
    echo "None found."
fi
echo ""
