#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APT_CLI_DIR="$(cd "$SCRIPT_DIR/../pipx" && pwd)"
PIPX_DIR="$(cd "$SCRIPT_DIR/../pipx" && pwd)"

echo "Running install-pipx.sh"
bash "$APT_CLI_DIR/install-pipx.sh"

for script in pipx-install-gallery-dl.sh pipx-install-yt-dlp.sh pipx-install-spotdl.sh; do
    echo "Running $script"
    bash "$PIPX_DIR/$script"
done

echo "Done."
