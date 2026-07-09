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
    echo -e "${YELLOW}Warning: Running as non-root. Journalctl logs might be restricted.${NC}\n"
fi

printf "\n${YELLOW}PACKAGES & LOGS:${NC}\n\n"

echo -e "${YELLOW}Installed Packages (Summary):${NC}"
if command -v dpkg-query >/dev/null 2>&1; then
    pkg_count=$(dpkg-query -f '${binary:Package}\n' -W 2>/dev/null | wc -l || echo "0")
    echo "Total packages installed via dpkg: $pkg_count"
elif command -v rpm >/dev/null 2>&1; then
    pkg_count=$(rpm -qa 2>/dev/null | wc -l || echo "0")
    echo "Total packages installed via rpm: $pkg_count"
else
    echo "Unsupported package manager."
fi

echo -e "\n${YELLOW}[*] Journal Errors (Last 15 critical/error events):${NC}"
if command -v journalctl >/dev/null 2>&1; then
    journalctl -p 3 -xb -n 15 --no-pager 2>/dev/null || echo "Permission denied to read journal."
else
    echo "journalctl not found."
fi

echo ""
