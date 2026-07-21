#!/bin/bash

set -euo pipefail
shopt -s nullglob

BLUE='\033[1;34m'
GREEN='\033[1;32m'
RESET='\033[0m'

show_file() {
    local file="$1"

    [[ -f "$file" ]] || return

    printf "${BLUE}%s${RESET}\n" \
        "=================================================================="
    printf "${GREEN}%s${RESET}\n" "$file"
    printf "${BLUE}%s${RESET}\n" \
        "=================================================================="

    cat "$file"
    echo
}

show_file /etc/apt/sources.list

for file in /etc/apt/sources.list.d/*.list; do
    show_file "$file"
done

for file in /etc/apt/sources.list.d/*.sources; do
    show_file "$file"
done
