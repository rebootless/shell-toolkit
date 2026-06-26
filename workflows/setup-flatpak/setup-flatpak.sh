#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLATPAK_DIR="$(cd "$SCRIPT_DIR/../../flatpak" && pwd)"

cd "$FLATPAK_DIR"

for script in install-flatpak.sh install-telegram.sh install-discord.sh install-steam.sh; do
    echo "[*] Running $script"
    bash "$script"
done

echo "[+] Done."
