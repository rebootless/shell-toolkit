#!/bin/bash

# ---DOC-START---
# summary: Listening TCP/UDP ports with the owning process, via ss.
# description: |
#   Read-only status and diagnostic script — does not modify system configuration. Works without root; colored output degrades gracefully to plain text when not attached to a terminal.
#
#   - Listening TCP/UDP ports with the owning process, via `ss`
#
#   > Running as `sudo` gives fuller process detail on this script; it still works without root, but with a warning and reduced detail.
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
for cmd in ss awk; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing commands: ${missing[*]}${NC}"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Running as non-root. Process information will be limited.${NC}"
fi

printf "\n${YELLOW}LISTENING PORTS (TCP/UDP):${NC}\n"

printf "%-8s %-25s %-8s %s\n" "Protocol" "Local Address" "Port" "Process"
echo "------------------------------------------------------------------------"

ss -Htnulp state listening 2>/dev/null | awk '
{
    split($4, localaddr, ":");
    port = localaddr[length(localaddr)];
    addr = substr($4, 1, length($4) - length(port) - 1);
    if (addr == "") addr = "*";

    proc = $NF;
    gsub(/users:\(\(/, "", proc);
    gsub(/\)\)/, "", proc);

    printf "%-8s %-25s %-8s %s\n", $1, addr, port, proc
}' | sort -k3 -n

echo ""
