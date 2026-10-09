#!/bin/bash

# ---DOC-START---
# summary: System-level DMI/SMBIOS hardware component info.
# description: |
#   Read-only status and diagnostic script.
#
#   - Collects system manufacturer/model/serial info via `dmidecode -t system`.
#
#   > Running as `sudo` is required; `dmidecode` returns no data for non-root users.
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

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Running as non-root. dmidecode may return no data.${NC}"
fi

printf "\n${YELLOW}DMI / SYSTEM HARDWARE INFO:${NC}\n\n"

if command -v dmidecode >/dev/null 2>&1; then
    dmidecode -t system 2>/dev/null || echo "Run as root to see dmidecode info."
else
    echo "dmidecode not installed."
fi

echo ""
