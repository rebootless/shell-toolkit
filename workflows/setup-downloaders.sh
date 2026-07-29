#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APT_CLI_DIR="$(cd "$SCRIPT_DIR/../standalone/install/apt/cli" && pwd)"
PIPX_DIR="$(cd "$SCRIPT_DIR/../standalone/install/pipx" && pwd)"

echo "Running install-pipx.sh"
bash "$APT_CLI_DIR/install-pipx.sh"

for script in install-gallery-dl.sh install-yt-dlp.sh install-spotdl.sh; do
    echo "Running $script"
    bash "$PIPX_DIR/$script"
done

echo "Done."
