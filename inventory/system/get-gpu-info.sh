#!/bin/bash

# ---DOC-START---
# summary: GPU hardware detection and live NVIDIA driver metrics.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Detects GPU devices via `lspci` (VGA/3D/display controllers).
#   - If `nvidia-smi` is present, also shows driver/CUDA version, per-GPU
#     temperature, utilization, memory usage, power draw, and active
#     compute processes.
#
#   > If no NVIDIA driver is found, run `install-nvidia-driver.sh` first.
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

command -v lspci >/dev/null 2>&1 || { echo -e "${RED}Missing command: lspci${NC}"; exit 1; }

printf "\n${YELLOW}GPU INFORMATION:${NC}\n\n"

echo -e "${YELLOW}Detected devices (lspci):${NC}"
gpu_lines="$(lspci | grep -Ei 'vga|3d controller|display controller' || true)"
if [[ -n "$gpu_lines" ]]; then
    echo "$gpu_lines"
else
    echo "No GPU devices detected."
fi

if command -v nvidia-smi >/dev/null 2>&1; then
    echo -e "\n${YELLOW}NVIDIA driver / live metrics (nvidia-smi):${NC}"
    nvidia-smi || echo "Permission denied or unavailable."
else
    echo -e "\n${YELLOW}NVIDIA driver:${NC} not found. Run install-nvidia-driver.sh if this is an NVIDIA card."
fi

echo ""
