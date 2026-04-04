#!/bin/bash

set -Eeuo pipefail

# System PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Auto-elevate to root if not already
if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

echo "Updating system packages..."
apt update && apt upgrade -y

echo "Installing required dependencies..."
apt install -y nginx ca-certificates curl wget

echo "Starting nginx..."
systemctl enable --now nginx

echo "Checking nginx status..."
systemctl status nginx --no-pager

echo "Checking log..."
LOG_FILE="/var/log/nginx/init_check.log"
nginx -t 2>&1 | tee "$LOG_FILE"

echo "--------------------PHP setup--------------------"
PHP_VERSION=""
read -p "Install PHP & PHP-FPM? [y/N]: " INSTALL_PHP
if [[ "$INSTALL_PHP" =~ ^([yY])$ ]]; then
    apt install -y php-fpm php
    PHP_VERSION=$(php -v | head -n 1 | cut -d " " -f 2 | cut -d "." -f 1-2)
fi

echo "-----------------Firewall setup------------------"
echo "Select Firewall: 1 - UFW, 2 - Firewalld, 0 - Skip"
read -p "Choice: " FW_CHOICE
case "$FW_CHOICE" in
    1)
        apt install -y ufw
        ufw allow 'Nginx Full'
        ufw allow OpenSSH
        echo "y" | ufw enable
        echo ""
        ;;
    2)
        apt install -y firewalld
        systemctl enable --now firewalld
        firewall-cmd --zone=public --list-services
        firewall-cmd --permanent --zone=public --add-service=http
        firewall-cmd --permanent --zone=public --add-service=https
        firewall-cmd --reload
        firewall-cmd --zone=public --list-services
        echo ""
        ;;
esac

echo "---------------Site configuration----------------"
LOCAL_IP=$(hostname -I | awk '{print $1}')
DEFAULT_IP=${LOCAL_IP:-"localhost"}

echo "Detected Local IP: $DEFAULT_IP"
read -p "Enter Domain, IP or press Enter for [$DEFAULT_IP]: " DOMAIN

DOMAIN=${DOMAIN:-$DEFAULT_IP}

WWW_PATH="/var/www/$DOMAIN"
CONF_PATH="/etc/nginx/sites-available/$DOMAIN"

mkdir -p "$WWW_PATH"
chown -R www-data:www-data "$WWW_PATH"

echo "Success! Your site root: $WWW_PATH"
echo "-------------------------------------------------"

echo "Creating index.html in $WWW_PATH..."
cat <<EOF > "$WWW_PATH/index.html"
<!doctype html>
<html>
<head><meta charset="utf-8"><title>$DOMAIN</title></head>
<body><h1>Nginx is working at $DOMAIN</h1></body>
</html>
EOF

echo "Generating Nginx server block at $CONF_PATH..."
cat <<EOF > "$CONF_PATH"
server {
    listen 80;
    server_name $DOMAIN;
    root $WWW_PATH;
    index index.html index.php;
    server_tokens off;

    location / {
        try_files \$uri \$uri/ =404;
    }

    $( [[ "$INSTALL_PHP" =~ ^([yY])$ ]] && echo "
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
    }")

    location /nginx_status {
        stub_status;
        allow 127.0.0.1;
        deny all;
    }
}
EOF

ln -sf "$CONF_PATH" /etc/nginx/sites-enabled/

# Final reload
if nginx -t; then
    systemctl reload nginx

    echo "-----------------Setup Complete!-----------------"
    echo "Server Info:"
    echo "  Domain/IP:        $DOMAIN"
    echo "  Local IP:         $DEFAULT_IP"
    echo ""
    echo "Paths:"
    echo "  Site Root:        $WWW_PATH"
    echo "  Index File:       $WWW_PATH/index.html"
    echo "  Nginx Config:     $CONF_PATH"
    echo "  Enabled Config:   /etc/nginx/sites-enabled/$(basename "$CONF_PATH")"
    echo "  Log File:         $LOG_FILE"
    echo ""

    if [[ "$INSTALL_PHP" =~ ^([yY])$ ]]; then
        echo "PHP:"
        echo "  Version:          $PHP_VERSION"
        echo "  FPM Socket:       /run/php/php$PHP_VERSION-fpm.sock"
        echo ""
    fi

    if [[ "$FW_CHOICE" == "1" ]]; then
        echo "Firewall: UFW enabled"
    elif [[ "$FW_CHOICE" == "2" ]]; then
        echo "Firewall: firewalld enabled (zone: public)"
    else
        echo "Firewall: not configured"
    fi

    echo ""
    echo "Access:"
    echo "  http://$DOMAIN"
    echo "-------------------------------------------------"
else
    echo "Configuration error found. Check $LOG_FILE"
fi
