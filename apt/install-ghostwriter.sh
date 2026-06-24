#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "[INFO] ghostwriter is a distraction-free Markdown editor with live preview,"
echo "       focus and fullscreen modes, word count, document navigation,"
echo "       and support for multiple Markdown processors,"
echo "       including built-in cmark-gfm and optional Pandoc integration."

echo "[*] Updating package lists..."
apt update

echo "[*] Installing kio-admin..."
apt install ghostwriter

echo "[+] ghostwriter installed successfully."
