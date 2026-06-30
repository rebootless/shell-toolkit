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

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Non-root mode. Firewall checks may fail or return incomplete info.${NC}\n"
fi

printf "\n${YELLOW}=== FIREWALL STATUS ===${NC}\n"

found_any=0

# UFW
if command -v ufw >/dev/null 2>&1; then
    echo "--> UFW:"
    ufw status 2>/dev/null || echo "  Unable to check UFW status."
    echo ""
    found_any=1
fi

# Firewalld
if command -v firewall-cmd >/dev/null 2>&1; then
    echo "--> Firewalld:"
    firewall-cmd --state 2>/dev/null || echo "  Unable to check Firewalld status."
    echo ""
    found_any=1
fi

# nftables
if command -v nft >/dev/null 2>&1; then
    echo "--> nftables (rule count):"
    nft list ruleset 2>/dev/null | grep -c 'type filter' | awk '{print "  Filter chains: "$1}' || echo "  Unable to check nftables."
    echo ""
    found_any=1
fi

# iptables (legacy fallback or rules check)
if command -v iptables >/dev/null 2>&1; then
    echo "--> iptables (rules summary):"
    iptables -L -n 2>/dev/null | grep -E '^Chain' || echo "  Unable to check iptables."
    echo ""
    found_any=1
fi

if [[ $found_any -eq 0 ]]; then
    echo "No supported firewall tooling found (ufw, firewalld, nft, iptables)."
    echo ""
fi
