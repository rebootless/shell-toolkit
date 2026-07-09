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
for cmd in lscpu free df lsblk; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Missing core commands: ${missing[*]}${NC}"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Running as non-root. Dmidecode and lshw may fail or show limited data.${NC}\n"
fi

printf "\n${YELLOW}HARDWARE RESOURCES:${NC}\n\n"

echo -e "${YELLOW}CPU Information (lscpu):${NC}"
lscpu | grep -E "^(Architecture|Model name|CPU\(s\)|Thread\(s\) per core|Core\(s\) per socket)"

echo -e "\n${YELLOW}Memory (free -h):${NC}"
free -h

echo -e "\n${YELLOW}Storage (df -h):${NC}"
df -h -x tmpfs -x devtmpfs

echo -e "\n${YELLOW}Block Devices (lsblk):${NC}"
lsblk

echo -e "\n${YELLOW}PCI Devices (lspci):${NC}"
if command -v lspci >/dev/null 2>&1; then lspci; else echo "lspci not installed."; fi

echo -e "\n${YELLOW}USB Devices (lsusb):${NC}"
if command -v lsusb >/dev/null 2>&1; then lsusb; else echo "lsusb not installed."; fi

echo -e "\n${YELLOW}DMI Decode (Hardware components):${NC}"
if command -v dmidecode >/dev/null 2>&1; then
    dmidecode -t system 2>/dev/null || echo "Run as root to see dmidecode info."
else
    echo "dmidecode not installed."
fi

echo ""
