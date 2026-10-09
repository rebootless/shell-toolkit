#!/bin/bash

# ---DOC-START---
# summary: Disk usage per mount point and block device layout.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Collects filesystem usage via `df -h` and block device layout via `lsblk`.
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
for cmd in df lsblk; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing core commands: ${missing[*]}${NC}"
    exit 1
fi

printf "\n${YELLOW}STORAGE INFORMATION:${NC}\n\n"

echo -e "${YELLOW}Filesystem Usage (df -h):${NC}"
df -h -x tmpfs -x devtmpfs

echo -e "\n${YELLOW}Block Devices (lsblk):${NC}"
lsblk

echo ""
