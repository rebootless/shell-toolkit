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
for cmd in ss awk; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing commands: ${missing[*]}${NC}"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Running as non-root. Process information will be limited.${NC}\n"
fi

printf "\n${YELLOW}ESTABLISHED CONNECTIONS:${NC}\n"

printf "%-6s %-25s %-25s %s\n" "Proto" "Local Endpoint" "Remote Endpoint" "Process"
echo "--------------------------------------------------------------------------------"

ss -Htnp state established 2>/dev/null | awk '
{
    proc = $NF;
    gsub(/users:\(\(/, "", proc);
    gsub(/\)\)/, "", proc);

    printf "%-6s %-25s %-25s %s\n", $1, $4, $5, proc
}' | sort -k2

echo ""
