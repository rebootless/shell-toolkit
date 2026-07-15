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

printf "\n${YELLOW}=== INTERFACE STATISTICS ===${NC}\n"

for iface_path in /sys/class/net/*; do
    [[ -d "$iface_path" ]] || continue
    iface="${iface_path##*/}"

    echo -e "Interface: ${YELLOW}$iface${NC}"

    stat_path="$iface_path/statistics"
    if [[ -d "$stat_path" ]]; then
        rx_bytes=$(cat "$stat_path/rx_bytes" 2>/dev/null || echo 0)
        tx_bytes=$(cat "$stat_path/tx_bytes" 2>/dev/null || echo 0)
        rx_packets=$(cat "$stat_path/rx_packets" 2>/dev/null || echo 0)
        tx_packets=$(cat "$stat_path/tx_packets" 2>/dev/null || echo 0)
        rx_errors=$(cat "$stat_path/rx_errors" 2>/dev/null || echo 0)
        tx_errors=$(cat "$stat_path/tx_errors" 2>/dev/null || echo 0)
        rx_dropped=$(cat "$stat_path/rx_dropped" 2>/dev/null || echo 0)
        tx_dropped=$(cat "$stat_path/tx_dropped" 2>/dev/null || echo 0)
        collisions=$(cat "$stat_path/collisions" 2>/dev/null || echo 0)

        if command -v numfmt >/dev/null 2>&1; then
            rx_human=$(numfmt --to=iec-i "$rx_bytes" 2>/dev/null || echo "$rx_bytes B")
            tx_human=$(numfmt --to=iec-i "$tx_bytes" 2>/dev/null || echo "$tx_bytes B")
        else
            rx_human=$(awk -v b="$rx_bytes" 'BEGIN{
                if (b>=1073741824) printf "%.2f GiB", b/1073741824
                else if (b>=1048576) printf "%.2f MiB", b/1048576
                else if (b>=1024) printf "%.2f KiB", b/1024
                else printf "%d B", b}')
            tx_human=$(awk -v b="$tx_bytes" 'BEGIN{
                if (b>=1073741824) printf "%.2f GiB", b/1073741824
                else if (b>=1048576) printf "%.2f MiB", b/1048576
                else if (b>=1024) printf "%.2f KiB", b/1024
                else printf "%d B", b}')
        fi

        printf "  RX: %-12s (%s packets) | Errors: %-4s | Dropped: %s\n" \
            "$rx_human" "$rx_packets" "$rx_errors" "$rx_dropped"
        printf "  TX: %-12s (%s packets) | Errors: %-4s | Dropped: %s\n" \
            "$tx_human" "$tx_packets" "$tx_errors" "$tx_dropped"
        echo "  Collisions: $collisions"
    else
        echo "  Statistics unavailable."
    fi
    echo ""
done
