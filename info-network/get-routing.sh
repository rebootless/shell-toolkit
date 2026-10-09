#!/bin/bash

# ---DOC-START---
# summary: IPv4/IPv6 routing tables and the default gateway/interface.
# description: |
#   Read-only status and diagnostic script — does not modify system configuration. Works without root; colored output degrades gracefully to plain text when not attached to a terminal.
#
#   - IPv4/IPv6 routing tables and the default gateway/interface
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

command -v ip >/dev/null 2>&1 || { echo -e "${RED}Missing command: ip${NC}"; exit 1; }

printf "\n${YELLOW}IPv4 ROUTING TABLE:${NC}\n"
ip -4 route show 2>/dev/null || echo "No IPv4 routes found."

printf "\n${YELLOW}IPv6 ROUTING TABLE:${NC}\n"
ip -6 route show 2>/dev/null || echo "No IPv6 routes found."

printf "\n${YELLOW}DEFAULT GATEWAY:${NC}\n"

def_gw4=$(ip -4 route show default 2>/dev/null | awk '{print $3}' | head -n1 || true)
def_iface4=$(ip -4 route show default 2>/dev/null | awk '{print $5}' | head -n1 || true)

def_gw6=$(ip -6 route show default 2>/dev/null | awk '{print $3}' | head -n1 || true)
def_iface6=$(ip -6 route show default 2>/dev/null | awk '{print $5}' | head -n1 || true)

echo -e "IPv4 Default Gateway   : ${def_gw4:-None}"
echo -e "IPv4 Default Interface : ${def_iface4:-None}"
echo -e "IPv6 Default Gateway   : ${def_gw6:-None}"
echo -e "IPv6 Default Interface : ${def_iface6:-None}"
echo ""
