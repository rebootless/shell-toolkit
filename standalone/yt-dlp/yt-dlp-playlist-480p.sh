#!/bin/bash

set -euo pipefail

if ! command -v yt-dlp &>/dev/null; then
    echo "Error: yt-dlp is not installed." >&2
    echo "Install it first, e.g.:" >&2
    echo "  sudo pipx install yt-dlp" >&2
    exit 1
fi

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
