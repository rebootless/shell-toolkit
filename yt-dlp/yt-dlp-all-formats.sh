#!/bin/bash

# ---DOC-START---
# summary: Download every resolution tier (480p-8K) via yt-dlp.
# description: |
#   Checks that `yt-dlp` is installed, uses Firefox cookies and a Node.js JS
#   runtime for restricted videos, and retries up to 100 times with
#   randomized sleep intervals. Output filenames always include uploader,
#   upload date, title, and video ID.
#
#   - Usage: `./yt-dlp-all-formats.sh <URL> [extra yt-dlp options]`
#   - Targets 480p, 720p, 1080p, 1440p, 2160p (4K), and 4320p (8K) with `bestaudio[ext=m4a]`
#   - Falls back to `best[ext=mp4]` / `best` if no matching tier is available
#   - Output filename also includes the resolution
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

yt-dlp -f 'bestvideo[height=480]+bestaudio[ext=m4a],
           bestvideo[height=720]+bestaudio[ext=m4a],
           bestvideo[height=1080]+bestaudio[ext=m4a],
           bestvideo[height=1440]+bestaudio[ext=m4a],
           bestvideo[height=2160]+bestaudio[ext=m4a],
           bestvideo[height=4320]+bestaudio[ext=m4a],
           bestvideo+bestaudio[ext=m4a]/best[ext=mp4]/best' \
  --merge-output-format mp4 \
  --retries 100 \
  --min-sleep-interval 3 \
  --max-sleep-interval 10 \
  --cookies-from-browser firefox \
  --js-runtimes node \
  --output "%(uploader).50B - %(upload_date>%Y-%m-%d)s - %(title).100B [%(id)s] (%(resolution)s).%(ext)s" \
  "$@"
