#!/bin/bash

# Clones all public repositories of a GitHub user into a local directory.
# Only PUBLIC repositories are fetched (no auth, GitHub public API only).
# Usage: ./git-clone-all.sh <github-username-or-profile-url> [target-dir]

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $# -lt 1 ]]; then
    echo "[!] Usage: $0 <github-username-or-url> [target-dir]"
    exit 1
fi

INPUT="$1"
DEST="${2:-./repos}"

# Extract username from URL or use as-is
USER=$(echo "$INPUT" | sed -E 's#https?://github\.com/##; s#/$##')

mkdir -p "$DEST"
cd "$DEST"

# Prefetch user info to validate and get total public repo count
user_info=$(curl -s "https://api.github.com/users/$USER")

if echo "$user_info" | grep -q '"message": "Not Found"'; then
    echo "[!] User not found: $USER"
    exit 1
fi

TOTAL=$(echo "$user_info" | grep -o '"public_repos": *[0-9]*' | grep -o '[0-9]*')

if [[ -z "$TOTAL" || "$TOTAL" -eq 0 ]]; then
    echo "[i] No public repositories found for: $USER"
    exit 0
fi

echo "[i] $TOTAL public repositories found for: $USER"

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
            echo "[i] [$counter/$TOTAL] Skipping existing: $name"
        else
            echo "[*] [$counter/$TOTAL] Cloning: $name"
            git clone --quiet "$url"
        fi
    done <<< "$urls"

    page=$((page + 1))
done

echo "[+] Done. Repositories saved in: $(pwd)"
