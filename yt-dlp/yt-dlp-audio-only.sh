#!/bin/bash

# yt-dlp-audio-only.sh
# Downloads audio only and converts it to MP3 (best quality).
# Usage: ./yt-dlp-audio-only.sh <URL> [extra yt-dlp options]

set -euo pipefail

echo "[*] Installing required dependencies..."
sudo apt-get install -y jq wget

yt-dlp -i \
  --extract-audio \
  --audio-format mp3 \
  --audio-quality 0 \
  --retries 100 \
  --min-sleep-interval 3 \
  --max-sleep-interval 10 \
  --cookies-from-browser firefox \
  --js-runtimes node \
  --output "%(uploader).50B - %(upload_date>%Y-%m-%d)s - %(title).100B [%(id)s].%(ext)s" \
  "$@"
