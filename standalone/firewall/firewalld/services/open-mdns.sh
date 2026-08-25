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

printf "\n${YELLOW}OPEN FIREWALLD SERVICE: MDNS${NC}\n\n"

if firewall-cmd --permanent --query-service=mdns >/dev/null 2>&1; then
    printf "${GREEN}Service mdns already allowed, skipping.${NC}\n"
else
    firewall-cmd --permanent --add-service=mdns
    firewall-cmd --reload
    printf "${GREEN}Service mdns opened.${NC}\n"
fi
