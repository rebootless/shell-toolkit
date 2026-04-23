#!/bin/bash

# Discord attachment downloader
#
# This script scans directories starting with "c*" (e.g. Discord channel exports),
# extracts attachment URLs from messages.json files, and downloads them locally.
#
# Workflow:
# 1. Finds all matching directories in the current path.
# 2. Optionally removes existing "attachments" folders.
# 3. For each directory:
#    - Reads messages.json
#    - Extracts Discord CDN attachment URLs using jq
#    - Saves URLs to a temporary file
#    - Downloads each file into ./attachments/
#    - Skips files that already exist
#    - Logs failed downloads to failed_links.log
#
# Output:
# - Downloaded files: <dir>/attachments/
# - Failed links log: ./failed_links.log
#
# Requirements:
# - jq (JSON parsing)
# - wget (file downloading)
#
# Notes:
# - Designed for Discord export formats with "Attachments" field
# - Safe to re-run (existing files are skipped)

set -euo pipefail

echo "[*] Updating system packages..."
sudo apt-get update

echo "[*] Installing required dependencies..."
sudo apt-get install -y jq wget

ERROR_LOG="failed_links.log"
> "$ERROR_LOG"

TOTAL_FOUND=0
TOTAL_SUCCESS=0
TOTAL_ERRORS=0
TOTAL_SKIPPED=0

mapfile -t ALL_DIRS < <(find . -maxdepth 1 -type d -name "c*" | sort)

if [[ ${#ALL_DIRS[@]} -eq 0 ]]; then
    echo "[!] No directories starting with 'c' were found"
    exit 1
fi

echo "[i] Total directories discovered: ${#ALL_DIRS[@]}"

read -rp "[?] Clean all 'attachments' folders? [y/N]: " CLEAN_CHOICE

case "${CLEAN_CHOICE,,}" in
    y|yes)
        echo "[+] Removing old attachments..."
        for dir in "${ALL_DIRS[@]}"; do
            rm -rf "${dir#./}/attachments"
        done
        echo "[+] Cleanup complete"
        ;;
    n|no|"")
        echo "[i] Cleanup skipped (existing files will be reused)"
        ;;
    *)
        echo "[!] Invalid input -> skipping cleanup"
        ;;
esac

for dir in "${ALL_DIRS[@]}"; do
    dir=${dir#./}
    json="$dir/messages.json"

    [[ -f "$json" ]] || continue

    echo ""
    echo "[*] Processing directory: $dir"

    jq -r '.[] | .Attachments // empty' "$json" \
        | tr ' ' '\n' \
        | grep 'https://cdn\.discordapp\.com/' \
        | sed 's/[:]$//' > "$dir/links.tmp"

    DIR_FOUND=$(wc -l < "$dir/links.tmp")

    if [[ "$DIR_FOUND" -eq 0 ]]; then
        echo "[i] No links found"
        rm -f "$dir/links.tmp"
        continue
    fi

    echo "[i] Links found: $DIR_FOUND"

    mkdir -p "$dir/attachments"

    D_SUCCESS=0
    D_ERROR=0
    D_SKIPPED=0
    CURRENT=0

    while IFS= read -r url; do
        ((CURRENT++))

        filename=$(basename "$url")
        target="$dir/attachments/$filename"

        printf "\r[*] %d/%d" "$CURRENT" "$DIR_FOUND"

        if [[ -f "$target" ]]; then
            ((D_SKIPPED++))
            continue
        fi

        if wget -c -nc -nv -t 2 -T 15 \
            --user-agent="Mozilla/5.0" \
            "$url" -O "$target" &>/dev/null; then
            ((D_SUCCESS++))
        else
            ((D_ERROR++))
            echo "$url" >> "$ERROR_LOG"
        fi

    done < "$dir/links.tmp"

    echo ""
    echo "[+] Done: downloaded=$D_SUCCESS skipped=$D_SKIPPED errors=$D_ERROR"

    TOTAL_SUCCESS=$((TOTAL_SUCCESS + D_SUCCESS))
    TOTAL_ERRORS=$((TOTAL_ERRORS + D_ERROR))
    TOTAL_SKIPPED=$((TOTAL_SKIPPED + D_SKIPPED))
    TOTAL_FOUND=$((TOTAL_FOUND + DIR_FOUND))

    rm -f "$dir/links.tmp"
done
echo "[✓] Done"

echo "Total processed:  $TOTAL_FOUND"
echo "Downloaded:       $TOTAL_SUCCESS"
echo "Skipped:          $TOTAL_SKIPPED"
echo "Errors:           $TOTAL_ERRORS"

if [[ "$TOTAL_ERRORS" -gt 0 ]]; then
    echo "[!] Failed links saved to: $ERROR_LOG"
fi

