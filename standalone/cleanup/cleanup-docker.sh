#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "[!] Docker is not installed."
    exit 0
fi

echo "==> Docker cleanup"
read -rp "[?] Prune unused Docker data (dangling images, stopped containers, networks)? [y/N]: " CHOICE
case "${CHOICE,,}" in
    y|yes)
        docker system prune -f
        echo "[+] Basic Docker prune completed."

        read -rp "[?] Also remove unused images and volumes? [y/N]: " VOL_CHOICE
        case "${VOL_CHOICE,,}" in
            y|yes)
                read -rp "[?] Type 'yes' to confirm removal of images and volumes: " CONFIRM
                if [[ "$CONFIRM" == "yes" ]]; then
                    docker system prune -af --volumes
                    echo "[+] Docker images and volumes removed."
                else
                    echo "[i] Skipped."
                fi
                ;;
            *)
                echo "[i] Skipped volumes and unused images."
                ;;
        esac
        ;;
    *)
        echo "[i] Docker cleanup skipped."
        ;;
esac
