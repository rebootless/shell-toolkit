#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/../standalone/install" && pwd)"

run_script() {
    local script="$1"

    if [[ ! -f "$script" ]]; then
        echo "Missing $script"
        return 1
    fi

    echo "Running $(basename "$script")"
    bash "$script"
}

echo "Running ranger setup..."

run_script "$INSTALL_DIR/apt/cli/install-ranger.sh"
run_script "$INSTALL_DIR/install-nerd-fonts.sh"
run_script "$INSTALL_DIR/install-ranger-devicons.sh"

echo "Done."
