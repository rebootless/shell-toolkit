#!/bin/bash

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

command -v sysctl >/dev/null 2>&1 || { echo -e "${RED}Missing command: sysctl${NC}"; exit 1; }

printf "\n${YELLOW}=== NETWORK KERNEL PARAMETERS (sysctl) ===${NC}\n"

cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "Unknown")
echo "TCP Congestion Control : $cc"

cc_avail=$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null || echo "Unknown")
echo "Available Cong. Algos  : $cc_avail"

ip4_fwd=$(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo "Unknown")
ip6_fwd=$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null || echo "Unknown")
ipv6_dis=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null || echo "Unknown")

echo "IPv4 Forwarding        : $([[ "$ip4_fwd" == "1" ]] && echo "Enabled" || echo "Disabled")"
echo "IPv6 Forwarding        : $([[ "$ip6_fwd" == "1" ]] && echo "Enabled" || echo "Disabled")"
echo "IPv6 Status            : $([[ "$ipv6_dis" == "1" ]] && echo "Disabled" || echo "Enabled")"

echo "BBR Enabled            : $(lsmod 2>/dev/null | grep -q bbr && echo "Yes" || echo "No/Unknown")"

echo ""
