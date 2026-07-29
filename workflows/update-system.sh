#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_DIR="$(cd "$SCRIPT_DIR/../standalone/update" && pwd)"

run_script() {
    local script="$1"

    if [[ ! -f "$script" ]]; then
        echo "Missing $script"
        return 1
    fi

    echo "Running $(basename "$script")"
    bash "$script"
}

echo "Running update scripts..."

run_script "$UPDATE_DIR/update-apt.sh"
run_script "$UPDATE_DIR/update-flatpak.sh"
run_script "$UPDATE_DIR/update-pipx.sh"

echo "Done."
