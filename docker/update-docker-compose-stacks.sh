#!/bin/bash

# ---DOC-START---
# summary: Pull and redeploy all Docker Compose stacks.
# description: |
#   Updates and redeploys every Docker Compose stack detected on the system.
#
#   - Lists currently running containers before starting
#   - Automatically discovers Docker Compose projects via Docker labels
#   - Runs `docker compose pull` followed by `docker compose up -d` for each stack
#   - Detects whether new images were actually pulled
#   - Skips stacks where the pull fails
#   - Prints a final summary of updated, unchanged, and skipped stacks
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

UPDATED=()
UNCHANGED=()
SKIPPED=()

echo "==> Current Containers"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'

echo "==> Discovering Compose stacks"

mapfile -t STACKS < <(
    docker ps -a \
        --format '{{.Label "com.docker.compose.project.working_dir"}}' |
    grep -v '^$' |
    sort -u
)

if [[ ${#STACKS[@]} -eq 0 ]]; then
    echo "No Docker Compose stacks found."
    exit 0
fi

echo "==> Updating Stacks"

for dir in "${STACKS[@]}"; do
    stack="$(basename "$dir")"

    if [[ ! -d "$dir" ]]; then
        echo "$stack: working directory not found, skipping"
        SKIPPED+=("$stack")
        continue
    fi

    echo "$stack: pulling images"
    pull_output="$(cd "$dir" && docker compose pull 2>&1)" || {
        echo "$stack: pull failed"
        echo "$pull_output"
        SKIPPED+=("$stack")
        continue
    }

    if grep -qiE 'Pulled|Downloaded newer image' <<< "$pull_output"; then
        is_updated=true
    else
        is_updated=false
    fi

    echo "$stack: applying (up -d)"
    (cd "$dir" && docker compose up -d) >/dev/null

    if [[ "$is_updated" == true ]]; then
        echo "$stack: updated"
        UPDATED+=("$stack")
    else
        echo "$stack: already up to date"
        UNCHANGED+=("$stack")
    fi
done

echo ""
echo "==> Summary"

echo ""
echo "  Updated:   ${UPDATED[*]:-none}"
echo "  Unchanged: ${UNCHANGED[*]:-none}"
echo "  Skipped:   ${SKIPPED[*]:-none}"
