#!/bin/bash

set -Eeuo pipefail

# System PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Auto-elevate to root if not already
if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

echo "-------------Installing dependencies-------------"
echo "Updating system packages..."
apt update

echo "Installing required dependencies..."
apt install -y nginx ca-certificates avahi-daemon

echo "Starting avahi-daemon..."
systemctl enable --now avahi-daemon

echo "Checking avahi-daemon status..."
systemctl status avahi-daemon --no-pager

echo "Starting nginx..."
systemctl enable --now nginx

echo "Checking nginx status..."
systemctl status nginx --no-pager

echo "Checking log..."
LOG_FILE="/var/log/nginx/init_check.log"
if ! nginx -t 2>&1 | tee "$LOG_FILE"; then
    echo "Configuration error found. Nginx was NOT reloaded."
    echo "Check details in: $LOG_FILE"
    exit 1
fi

echo "--------------------PHP setup--------------------"
PHP_VERSION=""
read -p "Install PHP & PHP-FPM? [y/N]: " INSTALL_PHP
if [[ "$INSTALL_PHP" =~ ^([yY])$ ]]; then
    apt install -y php php-fpm php-common php-mbstring php-xml php-curl

    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')

    if [ -z "$PHP_VERSION" ]; then
        echo "Error: PHP installation failed or version not detected."
        exit 1
    fi
fi

echo "-----------------Firewall setup------------------"
echo "Select Firewall: 1 - UFW, 2 - Firewalld, 0 - Skip"
read -p "Choice: " FW_CHOICE
case "$FW_CHOICE" in
    1)
        apt install -y ufw
        ufw allow 'Nginx Full'
        ufw allow OpenSSH
        ufw allow 5353/udp comment 'mDNS/Avahi'
        echo "y" | ufw enable
        echo ""
        ;;
    2)
        apt install -y firewalld
        systemctl enable --now firewalld
        firewall-cmd --zone=public --list-services
        firewall-cmd --permanent --zone=public --add-service=http
        firewall-cmd --permanent --zone=public --add-service=https
        firewall-cmd --permanent --zone=public --add-service=mdns
        firewall-cmd --reload
        firewall-cmd --zone=public --list-services
        echo ""
        ;;
esac

LOCAL_IP=$(hostname -I | awk '{print $1}')
DEFAULT_IP=${LOCAL_IP:-localhost}

echo "Domain configuration..."
read -p "Enter Domain, IP or press Enter for [$DEFAULT_IP]: " DOMAIN
DOMAIN=${DOMAIN:-$DEFAULT_IP}

# Basic validation: hostname or IPv4
if [[ ! "$DOMAIN" =~ ^([A-Za-z0-9.-]+|([0-9]{1,3}\.){3}[0-9]{1,3})$ ]]; then
    echo "Error: Invalid domain/IP format."
    exit 1
fi

WWW_PATH="/var/www/$DOMAIN"
CONF_PATH="/etc/nginx/sites-available/$DOMAIN"

mkdir -p "$WWW_PATH"
chown -R www-data:www-data "$WWW_PATH"

echo "---------------Site content setup----------------"
SHOULD_WRITE_INDEX="y"
BACKUP_TIME=$(date +%Y%m%d_%H%M%S)

if [[ -f "$WWW_PATH/index.html" || -f "$WWW_PATH/index.php" ]]; then
    echo "(!) Found existing index files in $WWW_PATH"
    read -p "Overwrite with default index.html? (Existing files will be backed up) [y/N]: " OVW_INDEX
    if [[ "$OVW_INDEX" =~ ^([yY])$ ]]; then
        [[ -f "$WWW_PATH/index.html" ]] && mv "$WWW_PATH/index.html" "$WWW_PATH/index.html.bak_$BACKUP_TIME"
        [[ -f "$WWW_PATH/index.php" ]] && mv "$WWW_PATH/index.php" "$WWW_PATH/index.php.bak_$BACKUP_TIME"
        echo "Old files moved to .bak_$BACKUP_TIME"
    else
        SHOULD_WRITE_INDEX="n"
        echo "Keeping existing site content."
    fi
fi

if [[ "$SHOULD_WRITE_INDEX" == "y" ]]; then
    echo "Creating standardized index.html..."
    cat <<EOF > "$WWW_PATH/index.html"
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>Welcome to $DOMAIN</title>
    <style>body{font-family:sans-serif;text-align:center;padding:50px;background:#f4f4f4;}</style>
</head>
<body>
    <h1>Nginx is working at $DOMAIN</h1>
    <p>Root directory: $WWW_PATH</p>
    <hr>
    <small>Managed by Automated Setup Script</small>
</body>
</html>
EOF
    chown www-data:www-data "$WWW_PATH/index.html"
fi

echo "---------------Nginx server block----------------"
SHOULD_WRITE_CONF="y"

if [[ -f "$CONF_PATH" ]]; then
    echo "(!) Configuration file $CONF_PATH already exists."
    read -p "Overwrite current Nginx config? (Existing config will be backed up) [y/N]: " OVW_CONF
    if [[ "$OVW_CONF" =~ ^([yY])$ ]]; then
        cp "$CONF_PATH" "$CONF_PATH.bak_$BACKUP_TIME"
        echo "Current config backed up to $CONF_PATH.bak_$BACKUP_TIME"
    else
        SHOULD_WRITE_CONF="n"
        echo "Skipping config generation, using existing file."
    fi
fi

if [[ "$SHOULD_WRITE_CONF" == "y" ]]; then
    echo "Generating standardized Nginx server block..."
    cat <<EOF > "$CONF_PATH"
server {
    listen 80;
    listen [::]:80; # IPv6 support

    server_name $DOMAIN;
    root $WWW_PATH;
    index index.php index.html index.htm;

    server_tokens off; # Security: hide nginx version

    # Logs specific to this domain
    access_log /var/log/nginx/${DOMAIN}_access.log;
    error_log /var/log/nginx/${DOMAIN}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { log_not_found off; access_log off; }

    $( [[ "$INSTALL_PHP" =~ ^([yY])$ ]] && echo "
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_intercept_errors on;
    }")

    location /nginx_status {
        stub_status;
        allow 127.0.0.1;
        allow ::1;
        deny all;
    }

    # Deny access to hidden files (like .git, .env)
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
fi

echo "Removing default Nginx site..."
rm -f /etc/nginx/sites-enabled/default
ln -sf "$CONF_PATH" /etc/nginx/sites-enabled/

# Final reload
if nginx -t; then
    systemctl reload nginx

    echo "-----------------Setup Complete!-----------------"
    echo "Server Info:"
    echo "  Domain/IP:        $DOMAIN"
    echo "  Local IP:         $DEFAULT_IP"

    # Avahi check
    if systemctl is-active --quiet avahi-daemon; then
        echo "  mDNS/Local:       http://$(hostname).local (if supported by client)"
    fi
    echo ""

    echo "Paths:"
    echo "  Site Root:        $WWW_PATH"
    echo "  Nginx Config:     $CONF_PATH"
    echo "  Access Log:       /var/log/nginx/${DOMAIN}_access.log"
    echo "  Error Log:        /var/log/nginx/${DOMAIN}_error.log"
    echo "  Init Log:         $LOG_FILE"
    echo ""

    if [[ "$INSTALL_PHP" =~ ^([yY])$ ]]; then
        echo "PHP-FPM:"
        echo "  Version:          $PHP_VERSION"
        echo "  FPM Socket:       /run/php/php$PHP_VERSION-fpm.sock"
        echo "  Status:           $(systemctl is-active php$PHP_VERSION-fpm)"
        echo ""
    fi

    echo "Security & Firewall:"
    if [[ "$FW_CHOICE" == "1" ]]; then
        echo "  Firewall:         UFW (Nginx Full, OpenSSH, mDNS allowed)"
    elif [[ "$FW_CHOICE" == "2" ]]; then
        echo "  Firewall:         Firewalld (HTTP, HTTPS, mDNS allowed)"
    else
        echo "  Firewall:         NOT CONFIGURED (Warning: ports might be closed)"
    fi
    echo "  Server Tokens:    OFF (Version hidden)"
    echo ""

    echo "Access your site at:"
    echo "  >> http://$DOMAIN"

    # Local IP note
    if [[ "$DOMAIN" != "$DEFAULT_IP" && "$DOMAIN" != *"."* ]]; then
        echo "Note: If '$DOMAIN' is not a real domain, add '$DEFAULT_IP $DOMAIN' to your hosts file."
    fi
else
    echo "//////////////////////////////////////////////////"
    echo "Configuration error found. Nginx was NOT reloaded."
    echo "Check details in: $LOG_FILE"
    echo "//////////////////////////////////////////////////"
    exit 1
fi
