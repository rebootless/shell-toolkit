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

printf "\n${YELLOW}=== Wi-Fi STATUS ===${NC}\n"

found=0
for iface_path in /sys/class/net/*; do
    [[ -d "$iface_path/wireless" ]] || continue
    found=1
    dev="${iface_path##*/}"

    echo -e "Wireless Interface: ${YELLOW}$dev${NC}"

    if command -v iw >/dev/null 2>&1; then
        iw dev "$dev" link 2>/dev/null | grep -E 'SSID|signal|tx bitrate|freq|Connected to' || echo "  Not connected or missing info."
    elif command -v nmcli >/dev/null 2>&1; then
        nmcli -t -f ACTIVE,SSID,SIGNAL,RATE,BSSID,FREQ dev wifi 2>/dev/null | grep -m1 '^yes' | awk -F: '{
            printf "  SSID            : %s\n", $2
            printf "  Signal Strength : %s%%\n", $3
            printf "  Bitrate         : %s\n", $4
            printf "  BSSID           : %s\n", $5
            printf "  Frequency       : %s MHz\n", $6
        }' || echo "  Not connected."
    else
        echo "  Neither 'iw' nor 'nmcli' found. Cannot display detailed Wi-Fi status."
    fi
    echo ""
done

[[ $found -eq 0 ]] && echo "No wireless interfaces found."
echo ""
