#!/bin/bash

# ---DOC-START---
# summary: Count of installed OS packages (dpkg or rpm).
# description: |
#   Read-only status and diagnostic script. Works without root.
#
#   - Counts installed packages via `dpkg-query` (Debian/Ubuntu) or `rpm` fallback.
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

printf "\n${YELLOW}INSTALLED PACKAGES:${NC}\n\n"

if command -v dpkg-query >/dev/null 2>&1; then
    pkg_count=$(dpkg-query -f '${binary:Package}\n' -W 2>/dev/null | wc -l || echo "0")
    echo "Total packages installed via dpkg: $pkg_count"
elif command -v rpm >/dev/null 2>&1; then
    pkg_count=$(rpm -qa 2>/dev/null | wc -l || echo "0")
    echo "Total packages installed via rpm: $pkg_count"
else
    echo "Unsupported package manager."
fi

echo ""
