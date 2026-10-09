#!/bin/bash

# ---DOC-START---
# summary: Active state of NetworkManager, systemd-networkd/-resolved, dhcpcd, wpa_supplicant, iwd.
# description: |
#   Read-only status and diagnostic script — does not modify system configuration. Works without root; colored output degrades gracefully to plain text when not attached to a terminal.
#
#   - Active state of NetworkManager, systemd-networkd/-resolved, dhcpcd, wpa_supplicant, iwd
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' NC=''
fi

trap 'echo -e "\n${RED}Script interrupted${NC}"; exit 130' INT TERM

printf "\n${YELLOW}NETWORK DAEMONS & SERVICES:${NC}\n"

if command -v systemctl >/dev/null 2>&1; then
    for srv in NetworkManager systemd-networkd systemd-resolved dhcpcd networking wpa_supplicant iwd; do
        if systemctl list-unit-files "$srv.service" >/dev/null 2>&1; then
            status=$(systemctl is-active "$srv.service" 2>/dev/null || echo "inactive")
            if [[ "$status" == "active" ]]; then
                printf " %-20s : %b\n" "$srv" "${GREEN}Active${NC}"
            else
                printf " %-20s : %b\n" "$srv" "${RED}Inactive/Failed${NC} ($status)"
            fi
        else
            printf " %-20s : Not installed\n" "$srv"
        fi
    done
else
    echo "systemd (systemctl) not found. Cannot check services."
fi

echo ""
echo "--> DHCP Client Processes:"
if pgrep -x "dhclient" >/dev/null; then
    echo "  dhclient is running."
elif pgrep -x "dhcpcd" >/dev/null; then
    echo "  dhcpcd is running."
else
    echo "  No standalone DHCP client processes detected."
fi
echo ""
