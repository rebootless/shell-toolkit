#!/bin/bash

# ---DOC-START---
# summary: Displays structural hierarchy of common server directories.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Displays a 2-level deep tree for /srv, /opt, and /var/www.
#
#   > Running as `sudo` prevents "Permission denied" errors in restricted folders.
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

missing=()
for cmd in tree; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing core commands: ${missing[*]}${NC}"
    echo -e "${YELLOW}Install with: apt-get install tree / yum install tree${NC}"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Running as non-root. Some directories might be unreadable.${NC}"
fi

printf "\n${YELLOW}DIRECTORY STRUCTURE:${NC}\n\n"

for target_dir in /srv /opt /var/www; do
    echo -e "${YELLOW}Tree view of ${target_dir} (Level 2):${NC}"
    if [[ -d "$target_dir" ]]; then
        tree -L 2 "$target_dir" 2>/dev/null || echo "Error reading $target_dir"
    else
        echo "Directory $target_dir does not exist."
    fi
    echo ""
done
