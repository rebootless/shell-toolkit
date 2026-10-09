#!/bin/bash

# ---DOC-START---
# summary: Hostname, OS release, kernel version, and uptime.
# description: |
#   Read-only status and diagnostic script — does not modify system configuration.
#   Works without root.
#
#   - Collects `hostnamectl`, `/etc/os-release`, `uname -a`, and `uptime`.
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

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
for cmd in hostnamectl uname uptime; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing commands: ${missing[*]}${NC}"
    exit 1
fi

printf "\n${YELLOW}HOST INFORMATION:${NC}\n\n"

echo -e "${YELLOW}Hostnamectl:${NC}"
hostnamectl || true

echo -e "\n${YELLOW}OS Release:${NC}"
cat /etc/os-release || true

echo -e "\n${YELLOW}Uname:${NC}"
uname -a

echo -e "\n${YELLOW}Uptime:${NC}"
uptime

echo ""
