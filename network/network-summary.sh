#!/bin/bash

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

gw_status="FAIL"
dns_status="FAIL"
int_status="FAIL"
pub_ipv4="Unavailable"
pub_ipv6="Unavailable"

gw4=$(ip -4 route show default 2>/dev/null | awk '{print $3}' | head -n1 || true)
[[ -n "$gw4" ]] && ping -c 1 -W 2 "$gw4" >/dev/null 2>&1 && gw_status="OK"

getent hosts google.com >/dev/null 2>&1 && dns_status="OK"

if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1 || curl -I -s --max-time 4 https://www.google.com >/dev/null 2>&1; then
    int_status="OK"
fi

pub_ipv4=$(curl -s --max-time 4 -4 https://api.ipify.org 2>/dev/null || echo "Unavailable")
pub_ipv6=$(curl -s --max-time 4 -6 https://api6.ipify.org 2>/dev/null || echo "Unavailable")

printf "\n${YELLOW}=== NETWORK DIAGNOSTIC SUMMARY ===${NC}\n"

printf "%-15s : " "Gateway"
[[ "$gw_status" == "OK" ]] && printf "%b\n" "${GREEN}OK${NC}" || printf "%b\n" "${RED}FAIL${NC}"

printf "%-15s : " "DNS"
[[ "$dns_status" == "OK" ]] && printf "%b\n" "${GREEN}OK${NC}" || printf "%b\n" "${RED}FAIL${NC}"

printf "%-15s : " "Internet"
[[ "$int_status" == "OK" ]] && printf "%b\n" "${GREEN}OK${NC}" || printf "%b\n" "${RED}FAIL${NC}"

printf "%-15s : " "Public IPv4"
[[ "$pub_ipv4" != "Unavailable" ]] && printf "%b (%s)\n" "${GREEN}OK${NC}" "$pub_ipv4" || printf "%b\n" "${RED}FAIL${NC}"

printf "%-15s : " "Public IPv6"
[[ "$pub_ipv6" != "Unavailable" ]] && printf "%b (%s)\n" "${GREEN}OK${NC}" "$pub_ipv6" || printf "%b\n" "${RED}FAIL${NC}"

if [[ "$gw_status" == "OK" && "$dns_status" == "OK" && "$int_status" == "OK" ]]; then
    echo -e "\n${GREEN}Overall Status: PASSED OK${NC}\n"
else
    echo -e "\n${RED}Overall Status: ISSUES DETECTED FAIL${NC}\n"
fi
