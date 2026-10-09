#!/usr/bin/env bash

# ---DOC-START---
# summary: Open or close firewalld services and ports by name
# description: Opens or closes well-known services (predefined firewalld services or port sets) as permanent rules in the default zone and reloads firewalld once if anything changed. #   Run without arguments to see the available names.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
trap 'exit 1' INT TERM

# name|type|ports|description
# type "service" = predefined firewalld service named <name>; type "port" = the listed ports
REGISTRY='dns|service|53/tcp 53/udp|DNS resolution
http|service|80/tcp|HTTP web server
https|service|443/tcp|HTTPS web server
localsend|port|53317/tcp 53317/udp|LocalSend file transfer
mdns|service|5353/udp|mDNS/Avahi service discovery
minecraft|port|25565/tcp 25565/udp|Minecraft game server
plex|port|32400/tcp|Plex media server
samba|service|139/tcp 445/tcp 137/udp 138/udp|Samba/CIFS file sharing
ssh|service|22/tcp|SSH remote access
syncthing|port|22000/tcp 22000/udp 21027/udp|Syncthing file synchronization
transmission|port|51413/tcp 51413/udp|Transmission BitTorrent client
wireguard|port|51820/udp|WireGuard VPN'

usage() {
    echo "Usage: ${0##*/} open|close <name>..."
    echo "       ${0##*/} --help"
    echo
    echo "Open or close services in the default firewalld zone (permanent rules)."
    echo
    echo "Available names:"
    printf '  %-13s %-8s %-40s %s\n' NAME TYPE PORTS DESCRIPTION
    local n t p d
    while IFS='|' read -r n t p d; do
        printf '  %-13s %-8s %-40s %s\n' "$n" "$t" "$p" "$d"
    done <<< "$REGISTRY"
}

find_entry() {
    local n p d
    while IFS='|' read -r n type ports d; do
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

if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "firewall-cmd not found. Install firewalld first." >&2
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

changed=0
for name in "$@"; do
    find_entry "$name"
    if [[ $type == service ]]; then
        flag=service
        items=("$name")
    else
        flag=port
        read -ra items <<< "$ports"
    fi

    echo "==> ${action^^} ${name^^}"
    for item in "${items[@]}"; do
        if firewall-cmd --permanent "--query-$flag=$item" >/dev/null 2>&1; then
            present=1
        else
            present=0
        fi

        if [[ $action == open ]]; then
            if [[ $present -eq 1 ]]; then
                echo "$item already open, skipping."
            else
                firewall-cmd --permanent "--add-$flag=$item"
                changed=1
            fi
        else
            if [[ $present -eq 1 ]]; then
                firewall-cmd --permanent "--remove-$flag=$item"
                changed=1
            else
                echo "$item already closed, skipping."
            fi
        fi
    done
done

if [[ $changed -eq 1 ]]; then
    firewall-cmd --reload
fi
