#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APT_CLI_DIR="$(cd "$SCRIPT_DIR/../standalone/apt/cli" && pwd)"
FLATPAK_DIR="$(cd "$SCRIPT_DIR/../standalone/flatpak" && pwd)"

echo "[*] Running install-flatpak.sh"
bash "$APT_CLI_DIR/install-flatpak.sh"

for script in install-telegram.sh install-discord.sh install-steam.sh; do
    echo "[*] Running $script"
    bash "$FLATPAK_DIR/$script"
done

echo "[+] Done."
