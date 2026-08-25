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

printf "\n${YELLOW}OPEN FIREWALLD PORT: SYNCTHING${NC}\n\n"

changed=0
if firewall-cmd --permanent --query-port=22000/tcp >/dev/null 2>&1; then
    printf "${GREEN}22000/tcp already open, skipping.${NC}\n"
else
    firewall-cmd --permanent --add-port=22000/tcp
    changed=1
    printf "${GREEN}22000/tcp opened.${NC}\n"
fi
if firewall-cmd --permanent --query-port=22000/udp >/dev/null 2>&1; then
    printf "${GREEN}22000/udp already open, skipping.${NC}\n"
else
    firewall-cmd --permanent --add-port=22000/udp
    changed=1
    printf "${GREEN}22000/udp opened.${NC}\n"
fi
if firewall-cmd --permanent --query-port=21027/udp >/dev/null 2>&1; then
    printf "${GREEN}21027/udp already open, skipping.${NC}\n"
else
    firewall-cmd --permanent --add-port=21027/udp
    changed=1
    printf "${GREEN}21027/udp opened.${NC}\n"
fi

if [ "$changed" -eq 1 ]; then
    firewall-cmd --reload
fi
