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

find "$ROOT" -type f -name '*.sh' -print0 |
while IFS= read -r -d '' file; do
    grep -nH -E '\b[Nn]ote:' "$file" || true
done
