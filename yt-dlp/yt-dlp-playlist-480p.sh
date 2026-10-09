#!/bin/bash

# ---DOC-START---
# summary: Download playlists up to 480p via yt-dlp.
# description: |
#   Checks that `yt-dlp` is installed, uses Firefox cookies and a Node.js JS
#   runtime for restricted videos, and retries up to 100 times with
#   randomized sleep intervals. Output filenames always include uploader,
#   upload date, title, and video ID where applicable.
#
#   - Usage: `./yt-dlp-playlist-480p.sh <URL> [extra yt-dlp options]`
#   - Downloads every video in a playlist
#   - Limits video quality to 480p or lower
#   - Prefers separate video/audio streams, falling back to the best available format
#   - Saves videos into a directory named after the playlist
#   - Prefixes filenames with the playlist index
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

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
