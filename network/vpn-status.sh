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

printf "\n${YELLOW}=== VPN & OVERLAY NETWORKS STATUS ===${NC}\n"

# Check WireGuard
echo "--> WireGuard:"
wg_found=0
for iface in /sys/class/net/wg*; do
    if [[ -d "$iface" ]]; then
        echo "  Found interface: ${iface##*/}"
        wg_found=1
    fi
done
[[ $wg_found -eq 0 ]] && echo "  Not active."

# Check OpenVPN (tun/tap)
echo -e "\n--> OpenVPN / TUN / TAP interfaces:"
tun_found=0
for iface in /sys/class/net/tun* /sys/class/net/tap*; do
    if [[ -d "$iface" ]]; then
        echo "  Found interface: ${iface##*/}"
        tun_found=1
    fi
done
[[ $tun_found -eq 0 ]] && echo "  Not active."

# Check Tailscale
echo -e "\n--> Tailscale:"
if command -v tailscale >/dev/null 2>&1; then
    tailscale status --peers=false 2>/dev/null | grep -v 'Logged out' | awk '{print "  "$0}' || echo "  Inactive or not authenticated."
else
    echo "  Not installed."
fi

# Check ZeroTier
echo -e "\n--> ZeroTier:"
if command -v zerotier-cli >/dev/null 2>&1; then
    if [[ $EUID -eq 0 ]]; then
        zerotier-cli status 2>/dev/null | awk '{print "  "$0}'
    else
        echo "  Requires root to check ZeroTier status."
    fi
else
    echo "  Not installed."
fi
echo ""
