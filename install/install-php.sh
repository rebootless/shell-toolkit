#!/bin/bash

# ---DOC-START---
# summary: Install PHP and common extensions.
# description: |
#   Installs `php`, `php-cli`, `php-common`, `php-mbstring`, `php-xml`, `php-curl`, `php-zip`, `php-intl`, `php-mysql`, `php-sqlite3`, `php-gd`, `php-xdebug`.
# sudo: true
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

echo "==> Installing PHP development environment"

echo "Updating package lists..."
apt update -q

echo "Installing PHP development environment..."
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

echo ""
echo "PHP development environment installed successfully."
