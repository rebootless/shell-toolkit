#!/bin/bash

# System cleanup for Debian/Ubuntu systems.
# Cleans APT caches, removes orphaned packages, rotates/truncates old logs.
# Clears journald history, and removes temp files and old kernels.
# Recommended for Debian 12/13 and Ubuntu 22.04/24.04 LTS.

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

LOG_AGE_DAYS=7

# Disk usage before cleanup (root filesystem)
SPACE_BEFORE=$(df --output=avail / | tail -1 | tr -d ' ')

echo "------------------APT cleanup---------------------"

echo "[*] Removing orphaned packages (autoremove)..."
apt-get autoremove -y

echo "[*] Removing obsolete .deb files from cache (autoclean)..."
apt-get autoclean -y

echo "[*] Clearing full APT package cache (clean)..."
apt-get clean

echo "[+] APT cleanup done."

echo "----------------Old kernels cleanup----------------"

CURRENT_KERNEL=$(uname -r)
echo "[i] Current kernel: $CURRENT_KERNEL"

mapfile -t OLD_KERNELS < <(dpkg -l 'linux-image-*' 2>/dev/null \
    | awk '/^ii/{print $2}' \
    | grep -v "$CURRENT_KERNEL" || true)

if [[ ${#OLD_KERNELS[@]} -gt 0 ]]; then
    echo "[i] Old kernel packages found:"
    printf '  - %s\n' "${OLD_KERNELS[@]}"

    read -rp "[?] Remove old kernel packages? [y/N]: " KERNEL_CHOICE
    case "${KERNEL_CHOICE,,}" in
        y|yes)
            apt-get purge -y "${OLD_KERNELS[@]}"
            echo "[+] Old kernels removed."
            ;;
        n|no|"")
            echo "[i] Old kernel cleanup skipped"
            ;;
        *)
            echo "[!] Invalid input -> skipping old kernel cleanup"
            ;;
    esac
else
    echo "[i] No old kernel packages found."
fi

echo "------------------Log cleanup----------------------"

echo "[*] Vacuuming journald logs older than ${LOG_AGE_DAYS} days..."
journalctl --vacuum-time=${LOG_AGE_DAYS}d >/dev/null
echo "[+] journald vacuumed."

echo "[*] Removing rotated logs in /var/log older than ${LOG_AGE_DAYS} days..."
# Only touches rotated/compressed logs (.gz, .1, .old) — active logs are left intact
find /var/log -type f \( -name "*.gz" -o -name "*.[0-9]" -o -name "*.old" \) \
    -mtime +${LOG_AGE_DAYS} -print -delete
echo "[+] Old rotated logs removed."

echo "------------------Temp file cleanup-----------------"

echo "[*] Removing files in /tmp older than ${LOG_AGE_DAYS} days..."
find /tmp -mindepth 1 -mtime +${LOG_AGE_DAYS} -print -delete 2>/dev/null || true

echo "[*] Removing files in /var/tmp older than ${LOG_AGE_DAYS} days..."
find /var/tmp -mindepth 1 -mtime +${LOG_AGE_DAYS} -print -delete 2>/dev/null || true

echo "[+] Temp files cleaned."

echo "------------------Docker cleanup--------------------"

if command -v docker >/dev/null 2>&1; then
    echo "[i] Docker detected."
    read -rp "[?] Prune unused Docker data (dangling images, stopped containers, unused networks/build cache)? [y/N]: " DOCKER_CHOICE

    case "${DOCKER_CHOICE,,}" in
        y|yes)
            docker system prune -f
            echo "[+] Docker pruned."

            read -rp "[?] Also remove unused images and volumes? [y/N]: " DOCKER_VOL_CHOICE
            case "${DOCKER_VOL_CHOICE,,}" in
                y|yes)
                    read -rp "[?] This may remove data still referenced by stopped containers. Type 'yes' to confirm: " DOCKER_VOL_CONFIRM
                    if [[ "$DOCKER_VOL_CONFIRM" == "yes" ]]; then
                        docker system prune -af --volumes
                        echo "[+] Unused images and volumes removed."
                    else
                        echo "[i] Confirmation not received — skipping."
                    fi
                    ;;
                n|no|"")
                    echo "[i] Skipped."
                    ;;
                *)
                    echo "[!] Invalid input -> skipping"
                    ;;
            esac
            ;;
        n|no|"")
            echo "[i] Docker cleanup skipped"
            ;;
        *)
            echo "[!] Invalid input -> skipping Docker cleanup"
            ;;
    esac
else
    echo "[i] Docker not installed — skipping."
fi

echo "----------------Thumbnail cache cleanup-------------"

THUMB_CLEANED=0
for home in /root /home/*; do
    THUMB_DIR="$home/.cache/thumbnails"
    if [[ -d "$THUMB_DIR" ]]; then
        rm -rf "${THUMB_DIR:?}"/*
        THUMB_CLEANED=$((THUMB_CLEANED + 1))
    fi
done

if [[ "$THUMB_CLEANED" -gt 0 ]]; then
    echo "[+] Cleared thumbnail caches in $THUMB_CLEANED home director$([[ $THUMB_CLEANED -eq 1 ]] && echo y || echo ies)."
else
    echo "[i] No thumbnail caches found."
fi

echo "-----------------Cleanup Complete!------------------"

SPACE_AFTER=$(df --output=avail / | tail -1 | tr -d ' ')
SPACE_FREED_KB=$((SPACE_AFTER - SPACE_BEFORE))

if [[ "$SPACE_FREED_KB" -gt 0 ]]; then
    SPACE_FREED_HUMAN=$(numfmt --from-unit=1024 --to=iec "$SPACE_FREED_KB")
else
    SPACE_FREED_HUMAN="0B"
fi

echo ""
echo -e "${GREEN}Cleanup summary:${NC}"
echo "  Space freed:      ~${SPACE_FREED_HUMAN}"
echo "  Free space now:   $(df -h / | awk 'NR==2 {print $4}')"
echo ""
echo -e "${YELLOW}[i]${NC} journald and rotated logs older than ${LOG_AGE_DAYS} days were removed."
echo -e "${YELLOW}[i]${NC} Run again periodically or schedule via cron."
