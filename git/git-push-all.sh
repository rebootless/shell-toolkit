#!/bin/bash

# ---DOC-START---
# summary: Push updates for all Git repositories in a directory.
# description: |
#   Pushes local commits from every Git repository located directly inside the selected `repositories/` / `gists/` subdirectories.
#
#   - Usage: `./git-push-all.sh <github-username-or-url> (--repositories | --gists | --all) [--path <dir>]`
#   - Accepts either a bare username or a full `github.com/<user>` URL
#   - Requires one of `--repositories`, `--gists` or `--all` (`--repositories --gists` equals `--all`)
#   - Defaults to the `./<username>` root (with `repositories/` and `gists/`) produced by `git-clone-all.sh`
#   - Pushes commits from each existing Git repository
#   - Skips directories that are not Git repositories
#   - Skips repositories with no commits to push
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

usage() {
    cat <<EOF
Usage: $0 <github-username-or-url> (--repositories | --gists | --all) [--path <dir>]

Arguments:
  <github-username-or-url>  Bare GitHub username or a github.com/<user> URL

Options:
  --repositories            Process <dir>/repositories/
  --gists                   Process <dir>/gists/
  --all                     Process both (same as --repositories --gists)
  --path <dir>              Root directory (default: ./<username>)
  -h, --help                Show this help message and exit
EOF
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

if [[ ! -d "$DEST" ]]; then
    echo "Error: directory does not exist: $DEST" >&2
    exit 1
fi

cd "$DEST"

SECTIONS=()
if [[ "$WANT_REPOS" -eq 1 ]]; then SECTIONS+=(repositories); fi
if [[ "$WANT_GISTS" -eq 1 ]]; then SECTIONS+=(gists); fi

REPOS=()
for section in "${SECTIONS[@]}"; do
    if [[ ! -d "$section" ]]; then
        echo "Skipping missing directory: $section" >&2
        continue
    fi
    while IFS= read -r dir; do
        REPOS+=("$dir")
    done < <(find "$section" -mindepth 1 -maxdepth 1 -type d -print | sort)
done

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
