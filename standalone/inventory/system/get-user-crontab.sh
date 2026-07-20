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

printf "\n${YELLOW}USER CRONTAB:${NC}\n\n"

if command -v crontab >/dev/null 2>&1; then
    crontab -l 2>/dev/null || echo "No crontab for current user or permission denied."
else
    echo "crontab not installed."
fi

echo ""
