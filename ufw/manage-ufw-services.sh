#!/bin/bash

set -euo pipefail
trap 'exit 1' INT TERM

# name|ports|description
REGISTRY='dns|53/tcp 53/udp|DNS resolution
http|80/tcp|HTTP web server
https|443/tcp|HTTPS web server
localsend|53317/tcp 53317/udp|LocalSend file transfer
mdns|5353/udp|mDNS/Avahi service discovery
minecraft|25565/tcp 25565/udp|Minecraft game server
plex|32400/tcp|Plex media server
samba|139/tcp 445/tcp 137/udp 138/udp|Samba/CIFS file sharing
ssh|22/tcp|SSH remote access
syncthing|22000/tcp 22000/udp 21027/udp|Syncthing file synchronization
transmission|51413/tcp 51413/udp|Transmission BitTorrent client
wireguard|51820/udp|WireGuard VPN'

usage() {
    echo "Usage: ${0##*/} open|close <name>..."
    echo "       ${0##*/} --help"
    echo
    echo "Open or close services in UFW (allow rules for incoming traffic)."
    echo
    echo "Available names:"
    printf '  %-13s %-40s %s\n' NAME PORTS DESCRIPTION
    local n p d
    while IFS='|' read -r n p d; do
        printf '  %-13s %-40s %s\n' "$n" "$p" "$d"
    done <<< "$REGISTRY"
}

find_entry() {
    local n d
    while IFS='|' read -r n ports d; do
        [[ $n == "$1" ]] && return 0
    done <<< "$REGISTRY"
    return 1
}

if [[ $# -eq 0 ]]; then
    usage
    exit 0
fi

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
    open|close)
        action=$1
        shift
        ;;
    *)
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
esac

if [[ $# -eq 0 ]]; then
    echo "No names given." >&2
    usage >&2
    exit 1
fi

if ! command -v ufw >/dev/null 2>&1; then
    echo "ufw not found. Install ufw first." >&2
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

for name in "$@"; do
    if ! find_entry "$name"; then
        echo "Unknown name: $name" >&2
        usage >&2
        exit 1
    fi
done

added=$(ufw show added)

for name in "$@"; do
    find_entry "$name"
    read -ra items <<< "$ports"

    echo ""
    echo "==> ${action^^} ${name^^}"
    for item in "${items[@]}"; do
        if grep -qxF "ufw allow $item" <<< "$added"; then
            present=1
        else
            present=0
        fi

        if [[ $action == open ]]; then
            if [[ $present -eq 1 ]]; then
                echo "$item already open, skipping."
            else
                ufw allow "$item"
            fi
        else
            if [[ $present -eq 1 ]]; then
                ufw delete allow "$item"
            else
                echo "$item already closed, skipping."
            fi
        fi
    done
done
