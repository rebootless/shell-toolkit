#!/bin/bash

# ---DOC-START---
# summary: SMART health status for all detected physical disks.
# description: |
#   Read-only status and diagnostic script.
#
#   - Enumerates physical disks via `lsblk` and reports SMART overall
#     health, temperature, power-on hours, and reallocated/pending
#     sector counts via `smartctl` (SATA, SAS, and NVMe).
#   - Complements `get-storage-info.sh`, which reports filesystem usage
#     rather than drive health.
#
#   > Running as `sudo` is required; `smartctl` returns limited or no
#   > data for non-root users.
# sudo: true
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

missing=()
for cmd in lsblk smartctl; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing core commands: ${missing[*]}${NC}"
    echo -e "${YELLOW}Install with: apt-get install smartmontools${NC}"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Running as non-root. smartctl may return no data.${NC}"
fi

printf "\n${YELLOW}DISK HEALTH (SMART):${NC}\n\n"

mapfile -t disks < <(lsblk -dn -o NAME,TYPE | awk '$2 == "disk" {print $1}')

if [[ ${#disks[@]} -eq 0 ]]; then
    echo "No physical disks detected."
fi

for disk in "${disks[@]}"; do
    dev="/dev/$disk"
    echo -e "${YELLOW}Device: $dev${NC}"

    smart_out="$(smartctl -H -A "$dev" 2>/dev/null || true)"
    if [[ -z "$smart_out" ]]; then
        echo "No SMART data (unsupported or virtual device)."
        echo ""
        continue
    fi

    filtered="$(echo "$smart_out" | grep -Ei 'overall-health|Temperature_Celsius|^Temperature:|Power_On_Hours|Reallocated_Sector_Ct|Current_Pending_Sector' || true)"
    if [[ -n "$filtered" ]]; then
        echo "$filtered"
    else
        echo "No matching SMART attributes found."
    fi
    echo ""
done
