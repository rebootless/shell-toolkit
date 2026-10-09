#!/bin/bash

# ---DOC-START---
# summary: Batch-convert .webm files to .mp4 using ffmpeg
# description: Recursively or non-recursively converts all .webm files in a target directory to .mp4 (H.264/AAC), skipping files that already have a converted output unless --force is given.
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---
# ---
set -euo pipefail

DIR="."
RECURSIVE=false
FORCE=false
DELETE_SOURCE=false
CRF=10
PRESET="medium"

usage() {
    printf '%s\n' "Usage: $(basename "$0") [options]"
    printf '%s\n' ""
    printf '%s\n' "Options:"
    printf '%s\n' "  --dir <path>       Directory to scan for .webm files (default: current directory)"
    printf '%s\n' "  --recursive        Search subdirectories as well"
    printf '%s\n' "  --force            Re-convert even if the .mp4 output already exists"
    printf '%s\n' "  --delete-source    Delete the .webm file after a successful conversion"
    printf '%s\n' "  --crf <n>          x264 CRF quality value, range 0-51, lower is better quality (default: 10)"
    printf '%s\n' "  --preset <name>    x264 encoding preset, one of:"
    printf '%s\n' "                       ultrafast, superfast, veryfast, faster"
    printf '%s\n' "                       fast, medium, slow, slower, veryslow"
    printf '%s\n' "                       (default: medium)"
    printf '%s\n' "  --help             Show this help message"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)
            DIR="$2"
            shift 2
            ;;
        --recursive)
            RECURSIVE=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --delete-source)
            DELETE_SOURCE=true
            shift
            ;;
        --crf)
            CRF="$2"
            if ! [[ "$CRF" =~ ^[0-9]+$ ]] || [[ "$CRF" -lt 0 || "$CRF" -gt 51 ]]; then
                printf '%s\n' "Invalid --crf value: $CRF (must be an integer 0-51)"
                exit 1
            fi
            shift 2
            ;;
        --preset)
            PRESET="$2"
            case "$PRESET" in
                ultrafast|superfast|veryfast|faster|fast|medium|slow|slower|veryslow) ;;
                *)
                    printf '%s\n' "Invalid --preset value: $PRESET"
                    printf '%s\n' "Must be one of: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow"
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            printf '%s\n' "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

CURRENT_OUTPUT=""

cleanup() {
    if [[ -n "$CURRENT_OUTPUT" && -f "$CURRENT_OUTPUT" ]]; then
        printf '%s\n' "Interrupted, removing incomplete file: $CURRENT_OUTPUT"
        rm -f "$CURRENT_OUTPUT"
    fi
    exit 130
}
trap cleanup INT TERM

if ! command -v ffmpeg >/dev/null 2>&1; then
    printf '%s\n' "ffmpeg is not installed."
    printf '%s\n' "Install it with: sudo apt-get install ffmpeg"
    exit 1
fi

if [[ ! -d "$DIR" ]]; then
    printf '%s\n' "Directory not found: $DIR"
    exit 1
fi

echo "==> Scanning for .webm files"

if [[ "$RECURSIVE" == true ]]; then
    mapfile -d '' FILES < <(find "$DIR" -type f -iname '*.webm' -print0)
else
    mapfile -d '' FILES < <(find "$DIR" -maxdepth 1 -type f -iname '*.webm' -print0)
fi

TOTAL=${#FILES[@]}

if [[ "$TOTAL" -eq 0 ]]; then
    printf '%s\n' "No .webm files found in: $DIR"
    exit 0
fi

printf '%s\n' "Found $TOTAL .webm file(s)"

CONVERTED=0
SKIPPED=0
FAILED=0

echo "==> Converting"

for SRC in "${FILES[@]}"; do
    OUT="${SRC%.[wW][eE][bB][mM]}.mp4"
    CURRENT_OUTPUT="$OUT"

    if [[ -f "$OUT" && "$FORCE" != true ]]; then
        printf '%s\n' "Skipping (already exists): $OUT"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    printf '%s\n' "Converting: $SRC"

    if ffmpeg -y -loglevel error -i "$SRC" \
        -c:v libx264 -preset "$PRESET" -crf "$CRF" \
        -c:a aac -b:a 192k \
        -movflags +faststart \
        "$OUT"; then
        printf '%s\n' "Done: $OUT"
        CONVERTED=$((CONVERTED + 1))
        if [[ "$DELETE_SOURCE" == true ]]; then
            rm -f "$SRC"
            printf '%s\n' "Removed source: $SRC"
        fi
    else
        printf '%s\n' "Failed: $SRC"
        rm -f "$OUT"
        FAILED=$((FAILED + 1))
    fi

    CURRENT_OUTPUT=""
done

echo ""
echo "==> Summary"

echo ""
printf '%s\n' "Converted: $CONVERTED"
printf '%s\n' "Skipped: $SKIPPED"
if [[ "$FAILED" -gt 0 ]]; then
    printf '%s\n' "Failed: $FAILED"
    exit 1
fi
