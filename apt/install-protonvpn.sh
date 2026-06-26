#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

PKG="protonvpn-stable-release_1.0.8_all.deb"
URL="https://repo.protonvpn.com/debian/dists/stable/main/binary-all/${PKG}"
SHA256="0b14e71586b22e498eb20926c48c7b434b751149b1f2af9902ef1cfe6b03e180"

echo "[*] Downloading Proton VPN repository package..."
wget -O "${PKG}" "${URL}"

echo "[*] Verifying package checksum..."
echo "${SHA256} ${PKG}" | sha256sum --check -

echo "[*] Installing Proton VPN repository..."
dpkg -i "./${PKG}"

echo "[*] Updating package lists..."
apt update

echo "[*] Installing Proton VPN..."
apt install -y proton-vpn-gnome-desktop

echo "[+] Proton VPN installation completed."
echo
echo "[NOTE] Log out and log back into your session"
     "       (or reboot) before launching Proton VPN for the first time."
