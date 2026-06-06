#!/bin/bash
set -euo pipefail
export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

# Usage: ./clone-all.sh <github-username-or-profile-url> [target-dir]

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

echo "[*] Fetching repository list for: $USER"

page=1
while :; do
    response=$(curl -s "https://api.github.com/users/$USER/repos?per_page=100&page=$page")

    # Check for API error
    if echo "$response" | grep -q '"message": "Not Found"'; then
        echo "[!] User not found: $USER"
        exit 1
    fi

    urls=$(echo "$response" | grep -o '"clone_url": *"[^"]*"' | sed -E 's/"clone_url": *"(.*)"/\1/')

    if [[ -z "$urls" ]]; then
        break
    fi

    while IFS= read -r url; do
        name=$(basename "$url" .git)
        if [[ -d "$name" ]]; then
            echo "[i] Skipping existing: $name"
        else
            echo "[*] Cloning: $name"
            git clone --quiet "$url"
        fi
    done <<< "$urls"

    page=$((page + 1))
done

echo "[+] Done. Repositories saved in: $(pwd)"
