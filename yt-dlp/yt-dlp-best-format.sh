#!/bin/bash

# ---DOC-START---
# summary: Download best quality video as MP4 via yt-dlp.
# description: |
#   Checks that `yt-dlp` is installed, uses Firefox cookies and a Node.js JS
#   runtime for restricted videos, and retries up to 100 times with
#   randomized sleep intervals. Output filenames always include uploader,
#   upload date, title, and video ID.
#
#   - Usage: `./yt-dlp-best-format.sh <URL> [extra yt-dlp options]`
#   - Prefers `bestvideo[ext=mp4]+bestaudio[ext=m4a]`, falling back to the best overall format
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

yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best[ext=mp4]/best' \
  --merge-output-format mp4 \
  --retries 100 \
  --min-sleep-interval 3 \
  --max-sleep-interval 10 \
  --cookies-from-browser firefox \
  --js-runtimes node \
  --output "%(uploader).50B - %(upload_date>%Y-%m-%d)s - %(title).100B [%(id)s].%(ext)s" \
  "$@"
