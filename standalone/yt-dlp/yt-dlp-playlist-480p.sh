#!/bin/bash

set -euo pipefail

echo "[*] Installing required dependencies..."
sudo apt-get install -y jq wget

yt-dlp \
  -f "bv*[height<=480]+ba/b[height<=480]/bv+ba/b" \
  --audio-quality 0 \
  --yes-playlist \
  --retries 100 \
  --min-sleep-interval 3 \
  --max-sleep-interval 10 \
  --cookies-from-browser firefox \
  --js-runtimes node \
  --output "%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s" \
  "$@"
