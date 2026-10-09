#!/bin/bash

# ---DOC-START---
# summary: Clone all public repositories and/or gists from a GitHub user/profile.
# description: |
#   Clones every public repository and/or gist belonging to a GitHub user or organization.
#
#   - Usage: `./git-clone-all.sh <github-username-or-url> (--repositories | --gists | --all) [--path <dir>]`
#   - Accepts either a bare username or a full `github.com/<user>` URL
#   - Requires one of `--repositories`, `--gists` or `--all` (`--repositories --gists` equals `--all`)
#   - Paginates through the GitHub API to fetch all items
#   - Clones repositories into `<dir>/repositories/<name>` and gists into `<dir>/gists/<gist_id>`
#   - Default root `<dir>` is `./<username>`
#   - Skips items that are already cloned locally
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

usage() {
    cat <<EOT
Usage: $0 <github-username-or-url> (--repositories | --gists | --all) [--path <dir>]

Arguments:
  <github-username-or-url>  Bare GitHub username or a github.com/<user> URL

Options:
  --repositories            Clone public repositories into <dir>/repositories/
  --gists                   Clone public gists into <dir>/gists/
  --all                     Clone both (same as --repositories --gists)
  --path <dir>              Root directory (default: ./<username>)
  -h, --help                Show this help message and exit
EOT
}

INPUT=""
DEST=""
WANT_REPOS=0
WANT_GISTS=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --repositories)
            WANT_REPOS=1
            shift
            ;;
        --gists)
            WANT_GISTS=1
            shift
            ;;
        --all)
            WANT_REPOS=1
            WANT_GISTS=1
            shift
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

if [[ "$WANT_REPOS" -eq 0 && "$WANT_GISTS" -eq 0 ]]; then
    echo "Error: one of --repositories, --gists or --all is required" >&2
    usage >&2
    exit 1
fi

# Extract username from URL or use as-is
USER=$(echo "$INPUT" | sed -E 's#https?://github\.com/##; s#/$##')

if [[ -z "$DEST" ]]; then
    DEST="./$USER"
fi

mkdir -p "$DEST"
cd "$DEST"

# Prefetch user info to validate and get total public counts
user_info=$(curl -s "https://api.github.com/users/$USER")
if echo "$user_info" | grep -q '"message": "Not Found"'; then
    echo "User not found: $USER"
    exit 1
fi
if echo "$user_info" | grep -q 'rate limit exceeded'; then
    echo "Error: GitHub API rate limit exceeded, try again later" >&2
    exit 1
fi

# clone_section <name> <api-endpoint> <total-key> <url-key>
# Clones into ./<name>/<basename of url without .git>
clone_section() {
    local name="$1" endpoint="$2" total_key="$3" url_key="$4"
    local total counter=0 page=1 response urls url item

    total=$(echo "$user_info" | grep -o "\"$total_key\": *[0-9]*" | grep -o '[0-9]*' || true)
    if [[ -z "$total" || "$total" -eq 0 ]]; then
        echo "No public $name found for: $USER"
        return 0
    fi

    echo "$total public $name found for: $USER"
    mkdir -p "$name"

    while :; do
        response=$(curl -s "https://api.github.com/users/$USER/$endpoint?per_page=100&page=$page")
        # || true prevents grep exit code 1 (no match) from killing the script via set -e
        urls=$(echo "$response" | grep -o "\"$url_key\": *\"[^\"]*\"" | sed -E "s/\"$url_key\": *\"(.*)\"/\1/" || true)
        if [[ -z "$urls" ]]; then
            break
        fi
        while IFS= read -r url; do
            item=$(basename "$url" .git)
            counter=$((counter + 1))
            if [[ -d "$name/$item" ]]; then
                echo "[$name $counter/$total] Skipping existing: $item"
            else
                echo "[$name $counter/$total] Cloning: $item"
                git clone --quiet "$url" "$name/$item"
            fi
        done <<< "$urls"
        page=$((page + 1))
    done
}

if [[ "$WANT_REPOS" -eq 1 ]]; then
    clone_section repositories repos public_repos clone_url
fi

if [[ "$WANT_GISTS" -eq 1 ]]; then
    clone_section gists gists public_gists git_pull_url
fi

echo "Done. Repositories saved in: $(pwd)"
