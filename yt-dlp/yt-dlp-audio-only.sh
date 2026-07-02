#!/bin/bash

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
