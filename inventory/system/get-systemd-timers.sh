#!/bin/bash

# ---DOC-START---
# summary: All systemd timers and the health of the units they activate.
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Lists every systemd timer via `systemctl list-timers`, showing next
#     and last run times and the unit each one activates.
#   - Cross-checks each activated unit and flags any currently in a
#     failed state.
#   - Complements crontab-based scheduling reports, which do not cover
#     systemd timers.
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

command -v systemctl >/dev/null 2>&1 || { echo -e "${RED}Missing command: systemctl${NC}"; exit 1; }

printf "\n${YELLOW}SYSTEMD TIMERS:${NC}\n\n"

systemctl list-timers --all --no-pager 2>/dev/null || echo "Unable to list timers."

echo -e "\n${YELLOW}Failed units activated by timers:${NC}"

mapfile -t timers < <(systemctl list-units --all --type=timer --no-legend --no-pager 2>/dev/null | awk '{print $1}')

found_failed=0
for timer in "${timers[@]}"; do
    unit="$(systemctl show "$timer" -p Unit --value 2>/dev/null || true)"
    [[ -z "$unit" ]] && continue
    if [[ "$(systemctl is-failed "$unit" 2>/dev/null || true)" == "failed" ]]; then
        echo -e "  ${RED}$unit (via $timer)${NC}"
        found_failed=1
    fi
done
[[ "$found_failed" -eq 0 ]] && echo "  None."

echo ""
