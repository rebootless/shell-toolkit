#!/bin/bash

# ---DOC-START---
# summary: Update APT, Flatpak and pipx packages in one step.
# description: |
#   Updates all supported package managers by chaining standalone update scripts.
#
#   - Runs in order: `update-apt.sh`, `update-flatpak.sh`, `update-pipx.sh`
# sudo: false
# interactive: false
# idempotent: true
# dependencies: update/update-apt.sh, flatpak/update-flatpak.sh, pipx/update-pipx.sh
# ---DOC-END---

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_DIR="$(cd "$SCRIPT_DIR/../update" && pwd)"
FLATPAK_DIR="$(cd "$SCRIPT_DIR/../flatpak" && pwd)"
PIPX_DIR="$(cd "$SCRIPT_DIR/../pipx" && pwd)"

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
run_script "$FLATPAK_DIR/update-flatpak.sh"
run_script "$PIPX_DIR/update-pipx.sh"

echo "Done."
