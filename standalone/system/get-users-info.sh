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
for cmd in ps w last; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing core commands: ${missing[*]}${NC}"
    exit 1
fi

printf "\n${YELLOW}USERS & PROCESSES:${NC}\n\n"

echo -e "${YELLOW}Currently Logged-in Users (w):${NC}"
w

echo -e "\n${YELLOW}Last Logins (last -n 10):${NC}"
last -n 10

echo -e "\n${YELLOW}Processes (Top 10 by CPU usage):${NC}"
ps aux --sort=-%cpu | head -n 11

echo -e "\n${YELLOW}Local Users (/etc/passwd - non-system):${NC}"
awk -F: '($3 >= 1000 && $3 != 65534) {print $1" (UID: "$3")"}' /etc/passwd

echo -e "\n${YELLOW}User Crontab:${NC}"
if command -v crontab >/dev/null 2>&1; then
    crontab -l 2>/dev/null || echo "No crontab for current user or permission denied."
else
    echo "crontab not installed."
fi

echo ""
