#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APT_CLI_DIR="$(cd "$SCRIPT_DIR/../flatpak" && pwd)"
FLATPAK_DIR="$(cd "$SCRIPT_DIR/../flatpak" && pwd)"

echo "Running install-flatpak.sh"
bash "$APT_CLI_DIR/install-flatpak.sh"

for script in flatpak-install-telegram.sh flatpak-install-discord.sh flatpak-install-steam.sh; do
    echo "Running $script"
    bash "$FLATPAK_DIR/$script"
done

echo "Done."
