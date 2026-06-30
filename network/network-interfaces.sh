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

missing=()
for cmd in ip awk; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing commands: ${missing[*]}${NC}"
    exit 1
fi

printf "\n${YELLOW}=== NETWORK INTERFACES ===${NC}\n"

for iface_path in /sys/class/net/*; do
    [[ -d "$iface_path" ]] || continue
    iface="${iface_path##*/}"

    state=$(cat "$iface_path/operstate" 2>/dev/null || echo "unknown")
    mac=$(cat "$iface_path/address" 2>/dev/null || echo "N/A")
    mtu=$(cat "$iface_path/mtu" 2>/dev/null || echo "N/A")

    if command -v ethtool >/dev/null 2>&1; then
        driver=$(ethtool -i "$iface" 2>/dev/null | awk '/driver:/ {print $2}' || echo "N/A")
    else
        driver=$(basename "$(readlink -f "$iface_path/device/driver" 2>/dev/null)" 2>/dev/null || echo "N/A")
    fi

    echo -e "Interface : ${YELLOW}$iface${NC}"
    echo " State          : $state"
    echo " MAC            : $mac"
    echo " MTU            : $mtu"
    echo " Driver         : $driver"

    if [[ -r "$iface_path/speed" ]]; then
        speed=$(cat "$iface_path/speed" 2>/dev/null || true)
        [[ "$speed" =~ ^[0-9]+$ && "$speed" -gt 0 ]] && echo " Speed          : ${speed} Mb/s"
    fi

    # IPv4 addresses
    output=$(ip -o -4 addr show dev "$iface" 2>/dev/null | awk '{print $4}' || true)
    if [[ -z "$output" ]]; then
        echo " IPv4           : None"
    else
        global=""
        ll=""
        while IFS= read -r addr; do
            if [[ "$addr" == fe80:* ]]; then
                ll="$ll\n   $addr"
            else
                global="$global\n   $addr"
            fi
        done <<< "$output"
        [[ -n "$global" ]] && echo -e " IPv4 (Global)  :$global"
        [[ -n "$ll" ]] && echo -e " IPv4 (Link)    :$ll"
    fi

    # IPv6 addresses
    output=$(ip -o -6 addr show dev "$iface" 2>/dev/null | awk '{print $4}' || true)
    if [[ -z "$output" ]]; then
        echo " IPv6           : None"
    else
        global=""
        ll=""
        while IFS= read -r addr; do
            if [[ "$addr" == fe80:* ]]; then
                ll="$ll\n   $addr"
            else
                global="$global\n   $addr"
            fi
        done <<< "$output"
        [[ -n "$global" ]] && echo -e " IPv6 (Global)  :$global"
        [[ -n "$ll" ]] && echo -e " IPv6 (Link)    :$ll"
    fi

    echo ""
done
