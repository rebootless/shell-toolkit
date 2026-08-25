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

printf "\n${YELLOW}CLOSE FIREWALLD PORT: MINECRAFT${NC}\n\n"

changed=0
if firewall-cmd --permanent --query-port=25565/tcp >/dev/null 2>&1; then
    firewall-cmd --permanent --remove-port=25565/tcp
    changed=1
    printf "${GREEN}25565/tcp closed.${NC}\n"
else
    printf "${GREEN}25565/tcp already closed, skipping.${NC}\n"
fi
if firewall-cmd --permanent --query-port=25565/udp >/dev/null 2>&1; then
    firewall-cmd --permanent --remove-port=25565/udp
    changed=1
    printf "${GREEN}25565/udp closed.${NC}\n"
else
    printf "${GREEN}25565/udp already closed, skipping.${NC}\n"
fi

if [ "$changed" -eq 1 ]; then
    firewall-cmd --reload
fi
