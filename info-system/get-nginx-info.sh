#!/bin/bash

# ---DOC-START---
# summary: Nginx version, compilation flags, and configuration check.
# description: |
#   Read-only status and diagnostic script.
#
#   - Collects nginx -V and checks config syntax.
#
#   > Running as `sudo` is required to read SSL certificates or specific config files during `nginx -t`.
# sudo: true
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

if ! command -v nginx >/dev/null 2>&1; then
    echo -e "\n${YELLOW}Nginx is not installed on this system.${NC}"
    exit 0
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Running as non-root. Config test (nginx -t) might fail due to permissions.${NC}"
fi

printf "\n${YELLOW}NGINX INFORMATION:${NC}\n\n"

echo -e "${YELLOW}Nginx Version & Build Info:${NC}"
nginx -V 2>&1

echo -e "\n${YELLOW}Configuration Test (nginx -t):${NC}"
nginx -t 2>&1 || true

# We skip `nginx -T` (full config dump) to avoid flooding the terminal with thousands of lines,
# unless specifically piped.

echo ""
