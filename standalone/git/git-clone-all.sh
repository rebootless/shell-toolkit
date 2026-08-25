#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

usage() {
    cat <<EOF
Usage: $0 <github-username-or-url> [--path <dir>]

Arguments:
  <github-username-or-url>  Bare GitHub username or a github.com/<user> URL

Options:
  --path <dir>              Target directory for cloned repos (default: ./<username>)
  -h, --help                Show this help message and exit
EOF
}

INPUT=""
DEST=""

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
            if [[ -n "$INPUT" ]]; then
                echo "Error: unexpected argument: $1" >&2
                usage
                exit 1
            fi
            INPUT="$1"
            shift
            ;;
    esac
done

if [[ -z "$INPUT" ]]; then
    usage
    exit 1
fi

# Extract username from URL or use as-is
USER=$(echo "$INPUT" | sed -E 's#https?://github\.com/##; s#/$##')

if [[ -z "$DEST" ]]; then
    DEST="./$USER"
fi

mkdir -p "$DEST"
cd "$DEST"

# Prefetch user info to validate and get total public repo count
user_info=$(curl -s "https://api.github.com/users/$USER")
if echo "$user_info" | grep -q '"message": "Not Found"'; then
    echo "User not found: $USER"
    exit 1
fi

TOTAL=$(echo "$user_info" | grep -o '"public_repos": *[0-9]*' | grep -o '[0-9]*')
if [[ -z "$TOTAL" || "$TOTAL" -eq 0 ]]; then
    echo "No public repositories found for: $USER"
    exit 0
fi

echo "$TOTAL public repositories found for: $USER"

counter=0
page=1
while :; do
    response=$(curl -s "https://api.github.com/users/$USER/repos?per_page=100&page=$page")
    # || true prevents grep exit code 1 (no match) from killing the script via set -e
    urls=$(echo "$response" | grep -o '"clone_url": *"[^"]*"' | sed -E 's/"clone_url": *"(.*)"/\1/' || true)
    if [[ -z "$urls" ]]; then
        break
    fi
    while IFS= read -r url; do
        name=$(basename "$url" .git)
        counter=$((counter + 1))
        if [[ -d "$name" ]]; then
            echo "[$counter/$TOTAL] Skipping existing: $name"
        else
            echo "[$counter/$TOTAL] Cloning: $name"
            git clone --quiet "$url"
        fi
    done <<< "$urls"
    page=$((page + 1))
done

echo "Done. Repositories saved in: $(pwd)"
