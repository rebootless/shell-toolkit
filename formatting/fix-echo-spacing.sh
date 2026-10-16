#!/bin/bash

set -euo pipefail

usage() {
    printf 'Usage: %s [DIRECTORY]\n' "${0##*/}"
}

usage

if [[ $# -gt 1 ]]; then
    exit 2
fi

ROOT="${1:-.}"

if [[ ! -d "$ROOT" ]]; then
    printf 'Error: not a directory: %s\n' "$ROOT" >&2
    exit 2
fi

ROOT=$(realpath "$ROOT")

if [[ "$ROOT" != "/home" && "$ROOT" != /home/* ]]; then
    printf 'Error: only /home is allowed: %s\n' "$ROOT" >&2
    exit 2
fi

TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

files=()
temps=()

while IFS= read -r -d '' file; do
    tmp="$TMPDIR_WORK/${#files[@]}"

    awk '
        /^[[:space:]]*echo "==>/ {
            if (previous !~ /^[[:space:]]*echo ""[[:space:]]*$/) {
                match($0, /^[[:space:]]*/)
                print substr($0, 1, RLENGTH) "echo \"\""
            }
        }
        {
            print
            previous = $0
        }
    ' "$file" > "$tmp"

    if ! cmp -s "$file" "$tmp"; then
        files+=("$file")
        temps+=("$tmp")
    fi
done < <(find "$ROOT" -type f -name '*.sh' -print0)

if [[ ${#files[@]} -eq 0 ]]; then
    printf 'No changes needed.\n'
    exit 0
fi

printf '\nThe following files will be modified:\n'
printf '  %s\n' "${files[@]}"
printf '\n'

if ! IFS= read -r -p 'Apply changes? [y/N] ' answer; then
    answer=''
fi

case "$answer" in
    y|Y)
        for i in "${!files[@]}"; do
            cat "${temps[$i]}" > "${files[$i]}"
        done
        printf 'Changes applied to %d file(s).\n' "${#files[@]}"
        ;;
    *)
        printf 'Cancelled. No files modified.\n'
        ;;
esac
