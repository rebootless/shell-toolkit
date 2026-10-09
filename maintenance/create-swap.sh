#!/bin/bash

# ---DOC-START---
# summary: Create and activate a swap file of any size.
# description: |
#   Creates and activates a swap file at `/swapfile`.
#
#   - Usage: `./create-swap.sh --size <size> [--dry-run] [--yes]`
#   - `--size` accepts G, GB, GiB, M, MB, MiB, T, TB, TiB units (e.g. `4G`, `8192M`, `2GiB`)
#   - `--dry-run` shows what would be done without making any changes
#   - `--yes` skips the confirmation prompt when creating/resizing the swap file
#   - Detects and safely handles an existing swap file, prompting for confirmation
#     before a destructive create/resize (unless `--yes` or `--dry-run` is used)
#   - Enables the new swap immediately and persists it via `/etc/fstab`
# sudo: true
# interactive: true
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

SWAP_FILE="/swapfile"

usage() {
    echo "Usage: $0 --size <size> [--dry-run] [--yes]"
    echo ""
    echo "  --size <size>   Swap file size, e.g. 4G, 8192M, 2T, 4GB, 4GiB"
    echo "  --dry-run       Show what would be done, without making any changes"
    echo "  --yes           Skip the confirmation prompt"
    echo "  -h, --help      Show this help message"
}

SIZE_RAW=""
DRY_RUN=false
ASSUME_YES=false

while [ $# -gt 0 ]; do
    case "$1" in
        --size)
            [ $# -ge 2 ] || { echo "Error: --size requires an argument."; exit 1; }
            SIZE_RAW="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --yes)
            ASSUME_YES=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown option '$1'"
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$SIZE_RAW" ]]; then
    usage
    exit 1
fi

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

SIZE_NORM="$(normalize_size "$SIZE_RAW" 2>/dev/null || true)"

if [[ -z "$SIZE_NORM" ]]; then
    echo "Error: invalid size: $SIZE_RAW"
    exit 1
fi

TARGET_SIZE_BYTES="$(numfmt --from=iec "$SIZE_NORM" 2>/dev/null || true)"
if [[ -z "${TARGET_SIZE_BYTES}" || "${TARGET_SIZE_BYTES}" -le 0 ]]; then
    echo "Error: invalid size: $SIZE_RAW"
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

confirm_or_abort() {
    local prompt="$1"

    if [[ "$ASSUME_YES" == true ]]; then
        return 0
    fi

    read -rp "$prompt (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
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
    echo "Another swap device already exists:"
    swapon --show
    echo "Nothing to do."
    exit 0
fi

CURRENT_SIZE_BYTES="$(current_size_bytes)"

if [[ ! -f "$SWAP_FILE" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "Dry-run: would create swap file ${SWAP_FILE} (${SIZE_NORM}) and enable it."
        echo "Dry-run: would add an entry for ${SWAP_FILE} to /etc/fstab."
        echo "Dry-run complete. No changes were made."
        exit 0
    fi

    confirm_or_abort "Create swap file ${SWAP_FILE} (${SIZE_NORM})?"

    echo "Creating swap file (${SIZE_NORM})..."
    create_or_resize_swapfile
    ensure_fstab_entry

elif [[ "$CURRENT_SIZE_BYTES" -ne "$TARGET_SIZE_BYTES" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "Dry-run: would resize existing swap file ${SWAP_FILE} to ${SIZE_NORM}."
        echo "Dry-run: this recreates the file, so its current contents will be discarded."
        echo "Dry-run complete. No changes were made."
        exit 0
    fi

    confirm_or_abort "Resize swap file ${SWAP_FILE} to ${SIZE_NORM}? This discards its current contents."

    echo "Resizing swap file to ${SIZE_NORM}..."
    create_or_resize_swapfile
    ensure_fstab_entry

else
    if [[ "$DRY_RUN" == true ]]; then
        echo "Swap file ${SWAP_FILE} is already the requested size (${SIZE_NORM})."
        if ! file -s "$SWAP_FILE" | grep -qi 'swap file'; then
            echo "Dry-run: would reinitialize the swap signature on ${SWAP_FILE}."
        fi
        if ! swapfile_active; then
            echo "Dry-run: would enable ${SWAP_FILE} with swapon."
        fi
        echo "Dry-run: would ensure ${SWAP_FILE} has an entry in /etc/fstab."
        echo "Dry-run complete. No changes were made."
        exit 0
    fi

    chmod 600 "$SWAP_FILE"

    if ! file -s "$SWAP_FILE" | grep -qi 'swap file'; then
        echo "Reinitializing swap signature..."
        if swapfile_active; then
            swapoff "$SWAP_FILE"
        fi
        mkswap "$SWAP_FILE" >/dev/null
    fi

    if ! swapfile_active; then
        swapon "$SWAP_FILE"
    fi

    ensure_fstab_entry
    echo "Swap file already configured."
fi

echo
echo "Current swap configuration:"
swapon --show
free -h
