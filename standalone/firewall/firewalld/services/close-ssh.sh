#!/usr/bin/env bash

set -euo pipefail
trap 'exit 1' INT TERM

if [ -t 1 ]; then
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    NC='\033[0m'
else
    YELLOW=''
    GREEN=''
    NC=''
fi

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "firewall-cmd not found. Install firewalld first." >&2
    exit 1
fi

printf "\n${YELLOW}CLOSE FIREWALLD SERVICE: SSH${NC}\n\n"

if firewall-cmd --permanent --query-service=ssh >/dev/null 2>&1; then
    firewall-cmd --permanent --remove-service=ssh
    firewall-cmd --reload
    printf "${GREEN}Service ssh closed.${NC}\n"
else
    printf "${GREEN}Service ssh already closed, skipping.${NC}\n"
fi
