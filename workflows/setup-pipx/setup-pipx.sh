#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLATPAK_DIR="$(cd "$SCRIPT_DIR/../../pipx" && pwd)"

cd "$FLATPAK_DIR"

for script in install-gallery-dl.sh install-yt-dlp.sh install-spotdl.sh; do
    echo "[*] Running $script"
    bash "$script"
done

echo "[+] Done."
