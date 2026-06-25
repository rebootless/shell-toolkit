#!/bin/bash

# update-stacks.sh
# Iterates over all docker compose stacks in /opt/*, runs
# `docker compose pull && docker compose up -d` for each, and
# reports which stacks had image updates.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

BASE_DIR="/opt"
UPDATED=()
UNCHANGED=()
SKIPPED=()

echo "----------------Current Containers---------------"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'

echo "-----------------Updating Stacks-----------------"

for dir in "$BASE_DIR"/*/; do
    stack="$(basename "$dir")"

    compose_file=""
    for f in docker-compose.yml compose.yml compose.yaml docker-compose.yaml; do
        if [[ -f "$dir$f" ]]; then
            compose_file="$f"
            break
        fi
    done

    if [[ -z "$compose_file" ]]; then
        echo "[i] $stack: no compose file found, skipping"
        SKIPPED+=("$stack")
        continue
    fi

    echo "[*] $stack: pulling images"
    pull_output="$(cd "$dir" && docker compose pull 2>&1)" || {
        echo "[!] $stack: pull failed"
        echo "$pull_output"
        SKIPPED+=("$stack")
        continue
    }

    # "up to date" lines mean no change for that image; anything else
    # ("Pulled", "Downloaded newer image", etc.) means an update happened
    if grep -qiE 'Pulled|Downloaded newer image' <<< "$pull_output"; then
        is_updated=true
    else
        is_updated=false
    fi

    echo "[*] $stack: applying (up -d)"
    (cd "$dir" && docker compose up -d) > /dev/null

    if [[ "$is_updated" == true ]]; then
        echo "[+] $stack: updated"
        UPDATED+=("$stack")
    else
        echo "[i] $stack: already up to date"
        UNCHANGED+=("$stack")
    fi
done

echo "---------------------Summary---------------------"
echo "[SUCCESS] Updated:   ${UPDATED[*]:-none}"
echo "          Unchanged: ${UNCHANGED[*]:-none}"
echo "          Skipped:   ${SKIPPED[*]:-none}"
