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

echo "[*] Installing PHP development environment..."
apt install -y \
    php \
    php-cli \
    php-common \
    php-mbstring \
    php-xml \
    php-curl \
    php-zip \
    php-intl \
    php-mysql \
    php-sqlite3 \
    php-gd \
    php-xdebug

echo "[+] PHP development environment installed successfully."
