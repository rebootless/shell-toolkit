#!/bin/bash

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path>"
    exit 1
fi

TARGET_PATH="$1"

if [ ! -e "$TARGET_PATH" ]; then
    echo "[!] Error: Path '$TARGET_PATH' does not exist."
    exit 1
fi

if ! command -v tree &> /dev/null; then
    echo "[*] 'tree' utility is not installed. Trying to install..."
    if [ "$EUID" -ne 0 ]; then
        echo "[!] Error: 'tree' is missing and root privileges are required to install it."
        echo "    Please run: sudo apt update && sudo apt install tree"
        exit 1
    fi
    apt-get update
    apt-get install -y tree
fi

ABS_PATH=$(readlink -f "$TARGET_PATH")

PREVENT_PATHS=(
    "/"
    "/boot"
    "/efi"
    "/etc"
    "/bin"
    "/sbin"
    "/usr"
    "/lib"
    "/lib64"
    "/libexec"
    "/var"
    "/opt"
    "/srv"
    "/sys"
    "/proc"
    "/dev"
    "/run"
    "/home"
    "/root"
    "/mnt"
    "/media"
)

for SYS_PATH in "${PREVENT_PATHS[@]}"; do
    if [[ "$ABS_PATH" == "$SYS_PATH" ]]; then
        echo "[FAIL] Operations on system directory '$SYS_PATH' are forbidden for safety!"
        exit 1
    fi
done

echo "=================================================="
echo " Target path: $ABS_PATH"
echo " Action:      Set permissions (755)"
echo "=================================================="
echo "Files to be modified:"

if [ -d "$ABS_PATH" ]; then
    tree -F "$ABS_PATH"
else
    echo "  -> $ABS_PATH (Single file)"
fi

echo "=================================================="
read -rp "Are you sure you want to set permissions to 755? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "[*] Cancelled by user."
    exit 0
fi

echo "[*] Setting permissions to 755..."

if [ -f "$ABS_PATH" ]; then
    chmod 755 "$ABS_PATH"
else
    find "$ABS_PATH" -type f -exec chmod 755 {} +
fi

echo "[+] Done successfully."
