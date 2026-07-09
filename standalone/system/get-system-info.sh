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
for cmd in hostnamectl uname uptime; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing commands: ${missing[*]}${NC}"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Running as non-root. `dmesg` and `sysctl` output will be limited or denied.${NC}\n"
fi

printf "\n${YELLOW}SYSTEM INFORMATION:${NC}\n\n"

echo -e "${YELLOW}Hostnamectl:${NC}"
hostnamectl || true

echo -e "\n${YELLOW}OS Release:${NC}"
cat /etc/os-release || true

echo -e "\n${YELLOW}Uname:${NC}"
uname -a

echo -e "\n${YELLOW}Uptime:${NC}"
uptime

echo -e "\n${YELLOW}Sysctl (Partial/All):${NC}"
sysctl -a 2>/dev/null | head -n 20
echo "(... output truncated for readability ...)"

echo -e "\n${YELLOW}Dmesg (Last 20 lines):${NC}"
dmesg 2>/dev/null | tail -n 20 || echo "Permission denied or unavailable."

echo ""
