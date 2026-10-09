#!/bin/bash

# ---DOC-START---
# summary: Running and enabled Systemd services.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Collects currently running services and enabled systemd units.
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
for cmd in systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing core commands: ${missing[*]}${NC}"
    exit 1
fi

printf "\n${YELLOW}SERVICE INFORMATION:${NC}\n\n"

echo -e "${YELLOW}Currently Running Services:${NC}"
systemctl --type=service --state=running --no-pager

echo -e "\n${YELLOW}Enabled Unit Files (Startup Services):${NC}"
systemctl list-unit-files --state=enabled --no-pager | grep "\.service" || true

echo ""
