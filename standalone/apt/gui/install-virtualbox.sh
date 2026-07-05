#!/bin/bash

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "[*] Updating package lists..."
apt update

echo "[*] Installing dependencies..."
apt install -y wget gnupg2 ca-certificates

echo "[*] Creating keyring directory..."
install -d -m 0755 /etc/apt/keyrings

echo "[*] Importing Oracle GPG key..."
wget -qO- https://www.virtualbox.org/download/oracle_vbox_2016.asc \
    | gpg --dearmor \
    > /etc/apt/keyrings/oracle-virtualbox.gpg

chmod 644 /etc/apt/keyrings/oracle-virtualbox.gpg

echo "[*] Detecting Debian version..."

DEBIAN_MAJOR="$(cut -d '.' -f1 /etc/debian_version)"

case "$DEBIAN_MAJOR" in
    13)
        REPOS=(trixie bookworm bullseye)
        ;;
    12)
        REPOS=(bookworm bullseye)
        ;;
    11)
        REPOS=(bullseye)
        ;;
    *)
        echo "[!] Unsupported Debian version: ${DEBIAN_MAJOR}"
        exit 1
        ;;
esac

FOUND=0

for REPO in "${REPOS[@]}"; do
    if wget -q --spider \
        "https://download.virtualbox.org/virtualbox/debian/dists/${REPO}/Release"; then
        REPO_CODENAME="$REPO"
        FOUND=1
        break
    fi
done

if [[ $FOUND -eq 0 ]]; then
    echo "[!] No compatible VirtualBox repository found."
    exit 1
fi

echo "[*] Using repository: ${REPO_CODENAME}"

echo "[*] Adding VirtualBox repository..."
cat > /etc/apt/sources.list.d/virtualbox.list <<EOF
deb [signed-by=/etc/apt/keyrings/oracle-virtualbox.gpg] https://download.virtualbox.org/virtualbox/debian ${REPO_CODENAME} contrib
EOF

echo "[*] Updating package lists..."
apt update

echo "[*] Detecting latest VirtualBox package..."
VBOX_PACKAGE=$(apt-cache pkgnames virtualbox- | grep -E '^virtualbox-[0-9]+\.[0-9]+$' | sort -V | tail -n 1)

if [[ -z "$VBOX_PACKAGE" ]]; then
    echo "[!] Could not dynamically determine the VirtualBox package name."
    exit 1
fi

echo "[*] Installing VirtualBox ($VBOX_PACKAGE)..."
apt install -y "$VBOX_PACKAGE"

echo
echo "[SUCCESS] VirtualBox ($VBOX_PACKAGE) installed successfully."
echo
if [[ "$DEBIAN_MAJOR" == "13" && "$REPO_CODENAME" != "trixie" ]]; then
    echo "[INFO] Repository for Debian 13 was not available."
    echo "       Using '${REPO_CODENAME}' repository instead."
    echo
fi
echo "[NOTE] It is recommended to reboot the system after installation so that the"
echo "       vboxdrv, vboxnetflt and vboxnetadp kernel modules are loaded correctly."
