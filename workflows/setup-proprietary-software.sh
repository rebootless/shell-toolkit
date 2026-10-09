#!/bin/bash

# ---DOC-START---
# summary: Install Flatpak + Flathub + Discord, Steam, Telegram in one step.
# description: |
#   Installs [Flatpak](https://flatpak.org) and a standard set of GUI applications in one step.
#
#   - Runs in order: `install-flatpak.sh` (Flatpak + Flathub), `install-telegram.sh`, `install-discord.sh`, `install-steam.sh`
# sudo: false
# interactive: false
# idempotent: true
# dependencies: flatpak/install-flatpak.sh, flatpak/flatpak-install-telegram.sh, flatpak/flatpak-install-discord.sh, flatpak/flatpak-install-steam.sh
# ---DOC-END---

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
