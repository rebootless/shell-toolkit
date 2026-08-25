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

if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not found. Install ufw first." >&2
    exit 1
fi

printf "\n${YELLOW}CLOSE UFW PORT: DNS${NC}\n\n"

ufw delete allow 53/tcp >/dev/null 2>&1 || true
ufw deny 53/tcp
ufw delete allow 53/udp >/dev/null 2>&1 || true
ufw deny 53/udp

printf "${GREEN}Done.${NC}\n"
