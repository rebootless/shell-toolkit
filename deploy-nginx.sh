#!/bin/bash

# Nginx deployment for Debian/Ubuntu systems.
# Installs nginx, optional PHP-FPM, creates a site root and vhost,
# and can configure firewalld for web access.
# Recommended for Debian 12/13 and Ubuntu 22.04/24.04 LTS.

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Auto-elevate to root
if [[ $EUID -ne 0 ]]; then
    echo "[!] Not running as root. Attempting to elevate..."
    exec sudo "$0" "$@"
fi

echo "-------------Installing dependencies-------------"

echo "[*] Updating system packages..."
apt-get update

echo "[*] Installing required dependencies..."
apt-get install -y nginx ca-certificates avahi-daemon

echo "[*] Starting services..."
systemctl enable --now avahi-daemon
systemctl enable --now nginx

LOG_FILE="/var/log/nginx/init_check.log"

echo "--------------------PHP setup--------------------"

INSTALL_PHP="n"
PHP_VERSION=""

read -rp "[?] Install PHP & PHP-FPM? [y/N]: " PHP_CHOICE

case "${PHP_CHOICE,,}" in
    y|yes)
        INSTALL_PHP="y"
        echo "[*] Installing PHP & PHP-FPM..."
        # FIX: Replaced 'php' with 'php-cli' to avoid installing Apache2
        apt-get install -y php-cli php-fpm php-common php-mbstring php-xml php-curl

        if command -v php >/dev/null 2>&1; then
            PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
        fi

        if [[ -z "$PHP_VERSION" ]]; then
            echo "[!] PHP installation failed or version not detected."
            exit 1
        fi
        ;;
    n|no|"")
        echo "[i] PHP installation skipped"
        ;;
    *)
        echo "[!] Invalid input -> skipping PHP"
        ;;
esac

PHP_BLOCK=""
if [[ -n "${PHP_VERSION}" ]]; then
    PHP_BLOCK="
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_intercept_errors on;
    }"
fi

echo "-----------------Grafana setup-------------------"

GRAFANA_BLOCK=""
read -rp "[?] Configure Grafana reverse proxy at /grafana? [y/N]: " GRAFANA_CHOICE

case "${GRAFANA_CHOICE,,}" in
    y|yes)
        echo "[*] Installing Docker..."
        apt-get install -y docker-compose

        echo "[*] Preparing Grafana proxy configuration..."
        GRAFANA_BLOCK="
    location = /grafana {
        return 301 /grafana/;
    }

    location /grafana/ {
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_pass http://127.0.0.1:3000;
    }"
        ;;
    n|no|"")
        echo "[i] Grafana proxy skipped"
        ;;
    *)
        echo "[!] Invalid input -> skipping Grafana proxy setup"
        ;;
esac

echo "-----------------Firewall setup------------------"

read -rp "[?] Install Firewalld? [y/N]: " FIREWALL_CHOICE

case "${FIREWALL_CHOICE,,}" in
    y|yes)
        echo "[*] Installing and configuring firewalld..."

        if apt-get install -y firewalld; then
            systemctl enable --now firewalld

            firewall-cmd --permanent --zone=public --add-service=http
            firewall-cmd --permanent --zone=public --add-service=https
            firewall-cmd --permanent --zone=public --add-service=mdns

            firewall-cmd --set-default-zone=public
            firewall-cmd --reload

            echo "[i] Active firewalld services:"
            firewall-cmd --zone=public --list-services
        else
            echo "[!] Failed to install firewalld"
        fi
        ;;
    n|no|"")
        echo "[i] Firewalld setup skipped"
        ;;
    *)
        echo "[!] Invalid input -> skipping firewalld setup"
        ;;
esac

echo "[*] Domain configuration..."

LOCAL_IP=$(ip -4 route get 1.1.1.1 | awk '{print $7; exit}')
DEFAULT_IP=${LOCAL_IP:-localhost}

read -rp "[>] Enter Domain, IP or press Enter for [$DEFAULT_IP]: " DOMAIN
DOMAIN=${DOMAIN:-$DEFAULT_IP}

if [[ ! "$DOMAIN" =~ ^([A-Za-z0-9.-]+|([0-9]{1,3}\.){3}[0-9]{1,3})$ ]]; then
    echo "[!] Invalid domain/IP format."
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
    read -rp "[?] Overwrite index? [y/N]: " OVW_INDEX
    if [[ "${OVW_INDEX,,}" =~ ^y ]]; then
        if [[ -f "$WWW_PATH/index.html" ]]; then
            BACKUP_FILE="$WWW_PATH/index.html.bak_$BACKUP_TIME"
            mv "$WWW_PATH/index.html" "$BACKUP_FILE"
            echo "[i] Backup created: $BACKUP_FILE"
        fi
        if [[ -f "$WWW_PATH/index.php" ]]; then
            BACKUP_FILE="$WWW_PATH/index.php.bak_$BACKUP_TIME"
            mv "$WWW_PATH/index.php" "$BACKUP_FILE"
            echo "[i] Backup created: $BACKUP_FILE"
        fi
    else
        SHOULD_WRITE_INDEX="n"
    fi
fi

if [[ "$SHOULD_WRITE_INDEX" == "y" ]]; then
    cat <<EOF > "$WWW_PATH/index.html"
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>Welcome to $DOMAIN</title>
</head>
<body>
    <h1>Nginx is working at $DOMAIN</h1>
    <p>Root: $WWW_PATH</p>
</body>
</html>
EOF
    chown www-data:www-data "$WWW_PATH/index.html"
fi

echo "------------------Nginx config-------------------"

SHOULD_WRITE_CONF="y"

if [[ -f "$CONF_PATH" ]]; then
    read -rp "[?] Overwrite nginx config? [y/N]: " OVW_CONF
    if [[ "${OVW_CONF,,}" =~ ^y ]]; then
        BACKUP_CONF="$CONF_PATH.bak_$BACKUP_TIME"
        cp "$CONF_PATH" "$BACKUP_CONF"
        echo "[i] Backup created: $BACKUP_CONF"
    else
        SHOULD_WRITE_CONF="n"
    fi
fi

if [[ "$SHOULD_WRITE_CONF" == "y" ]]; then
cat <<EOF > "$CONF_PATH"
server {
    listen 80;
    server_name $DOMAIN;
    root $WWW_PATH;

    index index.php index.html;

    server_tokens off;

    access_log /var/log/nginx/${DOMAIN}_access.log;
    error_log /var/log/nginx/${DOMAIN}_error.log;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt { access_log off; log_not_found off; }

    $PHP_BLOCK

    location ~ /\. {
        deny all;
    }
}
EOF
fi

echo "Removing default Nginx site..."
rm -f /etc/nginx/sites-enabled/default
ln -sf "$CONF_PATH" /etc/nginx/sites-enabled/

echo "[*] Enabling site..."
if nginx -t 2>&1 | tee "$LOG_FILE"; then
    systemctl reload nginx

    echo "------------------Setup Complete!----------------"
    echo "Server Info:"
    echo "  Domain/IP:        $DOMAIN"
    echo "  Local IP:         $DEFAULT_IP"

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

    if [[ "$INSTALL_PHP" == "y" ]]; then
        echo "PHP-FPM:"
        echo "  Version:          $PHP_VERSION"
        echo "  FPM Socket:       /run/php/php$PHP_VERSION-fpm.sock"
        echo "  Status:           $(systemctl is-active "php$PHP_VERSION-fpm" 2>/dev/null || echo inactive)"
        echo ""
    fi

    echo "Security & Firewall:"
    if [[ "${FIREWALL_CHOICE,,}" =~ ^(y|yes)$ ]]; then
        echo "  Firewall:         Firewalld (HTTP, HTTPS, mDNS allowed)"
    else
        echo "  Firewall:         NOT CONFIGURED (Warning: ports might be closed)"
    fi
    echo "  Server Tokens:    OFF (Version hidden)"
    echo ""

    echo "Access your site at:"
    echo "  >> http://$DOMAIN"

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
