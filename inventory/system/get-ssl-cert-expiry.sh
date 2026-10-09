#!/bin/bash

# ---DOC-START---
# summary: SSL/TLS certificate expiry status for one or more domains.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Connects to each domain (default port 443, or `host:port`) via
#     `openssl s_client` and reports the certificate's expiry date and
#     days remaining.
#   - Domains are given as CLI arguments, or edited into the `domains`
#     array at the top of the script.
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

command -v openssl >/dev/null 2>&1 || { echo -e "${RED}Missing command: openssl${NC}"; exit 1; }

# Edit this list if no domains are passed as CLI arguments.
domains=(
    # "example.com"
    # "example.com:8443"
)

if [[ $# -ge 1 ]]; then
    domains=("$@")
fi

if [[ ${#domains[@]} -eq 0 ]]; then
    echo -e "${RED}Usage: $0 <domain[:port]> [domain[:port] ...]${NC}"
    echo "Alternatively, edit the domains array at the top of this script."
    exit 1
fi

printf "\n${YELLOW}SSL CERTIFICATE EXPIRY:${NC}\n\n"

for entry in "${domains[@]}"; do
    host="${entry%%:*}"
    port="${entry#*:}"
    [[ "$port" == "$entry" ]] && port="443"

    echo -e "${YELLOW}$host:$port${NC}"

    end_date="$(echo | timeout 10 openssl s_client -connect "$host:$port" -servername "$host" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || true)"

    if [[ -z "$end_date" ]]; then
        echo -e "  ${RED}Could not retrieve certificate.${NC}"
        echo ""
        continue
    fi

    if ! end_epoch="$(date -d "$end_date" +%s 2>/dev/null)"; then
        echo -e "  ${RED}Could not parse expiry date: $end_date${NC}"
        echo ""
        continue
    fi
    now_epoch="$(date +%s)"
    days_left=$(( (end_epoch - now_epoch) / 86400 ))

    echo "  Expires: $end_date"
    if [[ "$days_left" -lt 0 ]]; then
        echo -e "  ${RED}EXPIRED $(( -days_left )) days ago${NC}"
    elif [[ "$days_left" -le 7 ]]; then
        echo -e "  ${RED}CRITICAL - $days_left days left${NC}"
    elif [[ "$days_left" -le 30 ]]; then
        echo -e "  ${YELLOW}WARNING - $days_left days left${NC}"
    else
        echo "  OK - $days_left days left"
    fi
    echo ""
done
