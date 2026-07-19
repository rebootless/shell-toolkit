#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

SWAP_FILE="/swapfile"

usage() {
    echo "Usage: $0 <size>"
    echo "Examples:"
    echo "  $0 4G"
    echo "  $0 8192M"
    echo "  $0 2T"
    echo "  $0 4GB"
    echo "  $0 4GiB"
    exit 1
}

[[ $# -eq 1 ]] || usage

normalize_size() {
    local raw="${1^^}"

    if [[ "$raw" =~ ^([0-9]+)([KMGTPE]?)(IB|B)?$ ]]; then
        local num="${BASH_REMATCH[1]}"
        local unit="${BASH_REMATCH[2]}"

        case "$unit" in
            "") echo "${num}" ;;
            K)  echo "${num}K" ;;
            M)  echo "${num}M" ;;
            G)  echo "${num}G" ;;
            T)  echo "${num}T" ;;
            P)  echo "${num}P" ;;
            E)  echo "${num}E" ;;
            *)   return 1 ;;
        esac
    else
        return 1
    fi
}

SIZE_RAW="$1"
SIZE_NORM="$(normalize_size "$SIZE_RAW" 2>/dev/null || true)"

if [[ -z "$SIZE_NORM" ]]; then
    echo "[!] Error: invalid size: $SIZE_RAW"
    exit 1
fi

TARGET_SIZE_BYTES="$(numfmt --from=iec "$SIZE_NORM" 2>/dev/null || true)"
if [[ -z "${TARGET_SIZE_BYTES}" || "${TARGET_SIZE_BYTES}" -le 0 ]]; then
    echo "[!] Error: invalid size: $SIZE_RAW"
    exit 1
fi

ensure_fstab_entry() {
    local entry="${SWAP_FILE} none swap sw 0 0"

    if ! grep -qE "^${SWAP_FILE}[[:space:]]+none[[:space:]]+swap[[:space:]]+" /etc/fstab; then
        echo "$entry" >> /etc/fstab
    fi
}

current_size_bytes() {
    if [[ -f "$SWAP_FILE" ]]; then
        stat -c '%s' "$SWAP_FILE"
    else
        echo 0
    fi
}

swapfile_active() {
    swapon --noheadings --show=NAME 2>/dev/null | awk '{print $1}' | grep -qxF "$SWAP_FILE"
}

other_swap_exists() {
    local active_swap
    local block_swap

    active_swap="$(
        swapon --noheadings --show=NAME 2>/dev/null | awk '{print $1}' \
        | grep -vxF "$SWAP_FILE" || true
    )"

    block_swap="$(
        blkid -t TYPE=swap -o device 2>/dev/null || true
    )"

    if [[ -n "$active_swap" || -n "$block_swap" ]]; then
        return 0
    fi

    return 1
}

create_or_resize_swapfile() {
    if swapfile_active; then
        swapoff "$SWAP_FILE"
    fi

    rm -f "$SWAP_FILE"

    if command -v fallocate >/dev/null 2>&1; then
        fallocate -l "$SIZE_NORM" "$SWAP_FILE"
    else
        local size_mb
        size_mb=$((TARGET_SIZE_BYTES / 1024 / 1024))
        if (( size_mb < 1 )); then
            size_mb=1
        fi
        dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$size_mb" status=progress
    fi

    chmod 600 "$SWAP_FILE"
    mkswap "$SWAP_FILE" >/dev/null
    swapon "$SWAP_FILE"
}

if other_swap_exists; then
    echo "[i] Another swap device already exists:"
    swapon --show
    echo "[i] Nothing to do."
    exit 0
fi

CURRENT_SIZE_BYTES="$(current_size_bytes)"

if [[ ! -f "$SWAP_FILE" ]]; then
    echo "[*] Creating swap file (${SIZE_NORM})..."
    create_or_resize_swapfile
    ensure_fstab_entry

elif [[ "$CURRENT_SIZE_BYTES" -ne "$TARGET_SIZE_BYTES" ]]; then
    echo "[*] Resizing swap file to ${SIZE_NORM}..."
    create_or_resize_swapfile
    ensure_fstab_entry

else
    chmod 600 "$SWAP_FILE"

    if ! file -s "$SWAP_FILE" | grep -qi 'swap file'; then
        echo "[*] Reinitializing swap signature..."
        if swapfile_active; then
            swapoff "$SWAP_FILE"
        fi
        mkswap "$SWAP_FILE" >/dev/null
    fi

    if ! swapfile_active; then
        swapon "$SWAP_FILE"
    fi

    ensure_fstab_entry
    echo "[+] Swap file already configured."
fi

echo
echo "[i] Current swap configuration:"
swapon --show
free -h
