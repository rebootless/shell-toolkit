#!/bin/bash

# ---DOC-START---
# summary: Same checks as network-summary.sh plus DNS query time and IPv6 internet reachability.
# description: |
#   Read-only status and diagnostic script — does not modify system configuration. Works without root; colored output degrades gracefully to plain text when not attached to a terminal.
#
#   - Same checks as `network-summary.sh` plus DNS query time and IPv6 internet reachability
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

missing=()
for cmd in ip ping getent curl awk; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing commands: ${missing[*]}${NC}"
    exit 1
fi

printf "\n${YELLOW}CONNECTIVITY CHECKS:${NC}\n"

gw_status="FAIL"
dns_status="FAIL"
int_status="FAIL"
ipv6_status="FAIL"
dns_time="N/A"

# Gateway reachability
gw4=$(ip -4 route show default 2>/dev/null | awk '{print $3}' | head -n1 || true)
if [[ -n "$gw4" ]]; then
    ping -c 1 -W 2 "$gw4" >/dev/null 2>&1 && gw_status="OK"
fi

# DNS Resolution
if getent hosts google.com >/dev/null 2>&1; then
    dns_status="OK"
    if command -v dig >/dev/null 2>&1; then
        dns_time=$(dig +stats +time=2 google.com 2>/dev/null | grep "Query time" | awk '{print $4" "$5}' || echo "N/A")
    else
        dns_time="(dig missing)"
    fi
fi

# Internet (ICMP + HTTP)
if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    int_status="OK"
elif curl -I -s --max-time 4 https://www.google.com >/dev/null 2>&1; then
    int_status="OK"
fi

# Optional IPv6 Internet
if ping -6 -c 1 -W 3 2001:4860:4860::8888 >/dev/null 2>&1; then
    ipv6_status="OK"
fi

printf "%-25s : " "Gateway Reachability"
[[ "$gw_status" == "OK" ]] && printf "%b\n" "${GREEN}OK${NC}" || printf "%b\n" "${RED}FAIL${NC}"

printf "%-25s : " "DNS Resolution"
[[ "$dns_status" == "OK" ]] && printf "%b (%s)\n" "${GREEN}OK${NC}" "$dns_time" || printf "%b\n" "${RED}FAIL${NC}"

printf "%-25s : " "Internet Connectivity"
[[ "$int_status" == "OK" ]] && printf "%b\n" "${GREEN}OK${NC}" || printf "%b\n" "${RED}FAIL${NC}"

printf "%-25s : " "IPv6 Connectivity"
[[ "$ipv6_status" == "OK" ]] && printf "%b\n" "${GREEN}OK${NC}" || printf "%b\n" "${RED}FAIL${NC}"

echo ""
