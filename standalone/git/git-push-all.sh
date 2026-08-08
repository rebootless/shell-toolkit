#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

usage() {
    cat <<EOF
Usage: $0 [--path <dir>]

Options:
  --path <dir>              Directory containing Git repositories (default: ./repos)
  -h, --help                Show this help message and exit
EOF
}

DEST="./repos"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --path)
            if [[ $# -lt 2 ]]; then
                echo "Error: --path requires an argument" >&2
                exit 1
            fi
            DEST="$2"
            shift 2
            ;;
        *)
            echo "Error: unexpected argument: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ ! -d "$DEST" ]]; then
    echo "Error: directory does not exist: $DEST" >&2
    exit 1
fi

cd "$DEST"

mapfile -t REPOS < <(
    find . -mindepth 1 -maxdepth 1 -type d -print | sort
)

TOTAL=${#REPOS[@]}

if [[ "$TOTAL" -eq 0 ]]; then
    echo "No directories found in: $(pwd)"
    exit 0
fi

echo "$TOTAL directories found in: $(pwd)"

counter=0

for repo in "${REPOS[@]}"; do
    name="${repo#./}"
    counter=$((counter + 1))

    if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "[$counter/$TOTAL] Skipping non-Git directory: $name"
        continue
    fi

    if ! git -C "$repo" remote get-url origin >/dev/null 2>&1; then
        echo "[$counter/$TOTAL] Skipping repository without origin: $name"
        continue
    fi

    if [[ -z "$(git -C "$repo" log -1 2>/dev/null)" ]]; then
        echo "[$counter/$TOTAL] Skipping repository without commits: $name"
        continue
    fi

    branch=$(git -C "$repo" branch --show-current)

    if [[ -z "$branch" ]]; then
        echo "[$counter/$TOTAL] Skipping detached HEAD: $name"
        continue
    fi

    upstream=$(git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)

    if [[ -z "$upstream" ]]; then
        echo "[$counter/$TOTAL] Skipping branch without upstream: $name"
        continue
    fi

    ahead=$(git -C "$repo" rev-list --count '@{u}..HEAD')

    if [[ "$ahead" -eq 0 ]]; then
        echo "[$counter/$TOTAL] Skipping up-to-date: $name"
        continue
    fi

    echo "[$counter/$TOTAL] Pushing: $name"

    if ! git -C "$repo" push --quiet; then
        echo "[$counter/$TOTAL] Failed: $name" >&2
    fi
done

echo "Done. Repositories processed in: $(pwd)"
