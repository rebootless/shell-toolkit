#!/bin/bash

# ---DOC-START---
# summary: Per-interface link speed, duplex, carrier state, and MTU.
# description: |
#   Read-only status and diagnostic script — does not modify system configuration. Works without root; colored output degrades gracefully to plain text when not attached to a terminal.
#
#   - Per-interface link speed, duplex, carrier state, and MTU
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

printf "\n${YELLOW}HARDWARE BANDWIDTH SUMMARY:${NC}\n"

printf "%-15s %-10s %-10s %-10s %-10s\n" "Interface" "Speed" "Duplex" "Carrier" "MTU"
echo "------------------------------------------------------------"

for iface_path in /sys/class/net/*; do
    [[ -d "$iface_path" ]] || continue
    iface="${iface_path##*/}"

    speed=$(cat "$iface_path/speed" 2>/dev/null || echo "N/A")
    [[ "$speed" != "N/A" ]] && speed="${speed} Mb/s"

    duplex=$(cat "$iface_path/duplex" 2>/dev/null || echo "N/A")

    carrier=$(cat "$iface_path/carrier" 2>/dev/null || echo "N/A")
    [[ "$carrier" == "1" ]] && carrier="UP"
    [[ "$carrier" == "0" ]] && carrier="DOWN"

    mtu=$(cat "$iface_path/mtu" 2>/dev/null || echo "N/A")

    printf "%-15s %-10s %-10s %-10s %-10s\n" "$iface" "$speed" "$duplex" "$carrier" "$mtu"
done
echo ""
