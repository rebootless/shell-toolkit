#!/bin/bash

# ---DOC-START---
# summary: Install and configure ranger with Nerd Fonts and ranger_devicons.
# description: |
#   Installs a complete ranger environment by chaining standalone scripts.
#
#   - Installs ranger.
#   - Installs popular Nerd Fonts.
#   - Installs and configures ranger_devicons.
# sudo: false
# interactive: false
# idempotent: true
# dependencies: install/install-ranger.sh, install/install-nerd-fonts.sh, install/install-ranger-devicons.sh
# ---DOC-END---

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/../install" && pwd)"

run_script() {
    local script="$1"
    local needs_root="${2:-false}"

    if [[ ! -f "$script" ]]; then
        echo "Missing $script"
        return 1
    fi

    echo "Running $(basename "$script")"

    if [[ "$needs_root" == true ]]; then
        if [[ $EUID -eq 0 ]]; then
            bash "$script"
        else
            sudo bash "$script"
        fi
    else
        # Must run as the real (non-root) user so $HOME resolves correctly,
        # even if this script itself was invoked with sudo.
        if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]]; then
            sudo -u "$SUDO_USER" -H bash "$script"
        elif [[ $EUID -eq 0 ]]; then
            echo "Running as root with no SUDO_USER set; cannot determine the target user's HOME." >&2
            echo "Run this script as your normal user (it will sudo internally when needed)." >&2
            return 1
        else
            bash "$script"
        fi
    fi
}

echo "Running ranger setup..."

run_script "$INSTALL_DIR/install-ranger.sh" true
run_script "$INSTALL_DIR/install-nerd-fonts.sh" true
run_script "$INSTALL_DIR/install-ranger-devicons.sh" false

echo "Done."
