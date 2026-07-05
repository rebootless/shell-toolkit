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
for cmd in date hostname uname uptime; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing commands: ${missing[*]}${NC}"
    exit 1
fi

printf "\n${YELLOW}SYSTEM INFORMATION:${NC}\n"

echo "Hostname     : $(hostname)"

os="Unknown"
if [[ -f /etc/os-release ]]; then
    os=$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2 || echo "Unknown")
fi
echo "OS           : $os"

echo "Kernel       : $(uname -r)"
echo "Architecture : $(uname -m)"

up=$(uptime -p 2>/dev/null || awk '{printf "%.2f hours", $1/3600}' /proc/uptime)
echo "Uptime       : $up"
echo "Current Date : $(date)"
echo ""
