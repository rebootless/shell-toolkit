#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEPLOY_DIR="/opt/filebrowser-stack"

# File Browser's bare Alpine image runs internally as this UID/GID by default.
FB_UID=1000
FB_GID=1000

if [[ -d "$DEPLOY_DIR" ]]; then
    echo ""
    echo -e "${RED}Directory $DEPLOY_DIR already exists.${NC}"
    echo -e "${RED}Proceeding will PERMANENTLY DELETE all data:${NC}"
    echo -e "${RED}    containers, volumes, database, served files.${NC}"
    echo -e "${RED}THIS ACTION IS IRREVERSIBLE.${NC}"
    echo ""
    read -rp "[?] Wipe existing File Browser stack and all data? [y/N]: " WIPE_CHOICE
    if [[ "${WIPE_CHOICE,,}" =~ ^y ]]; then
        read -rp "[?] Are you sure? This cannot be undone. Type 'yes' to confirm: " WIPE_CONFIRM
        if [[ "$WIPE_CONFIRM" == "yes" ]]; then
            echo "[*] Stopping and removing containers..."
            if [[ -f "$DEPLOY_DIR/compose.yaml" ]]; then
                docker compose -f "$DEPLOY_DIR/compose.yaml" down -v 2>/dev/null || true
            fi
            echo "[*] Deleting $DEPLOY_DIR..."
            rm -rf "$DEPLOY_DIR"
            echo "[+] Wiped."
        else
            echo "[i] Confirmation not received — aborting."
            exit 0
        fi
    else
        echo "[i] Wipe skipped — continuing with existing data."
    fi
    echo ""
fi

echo "==> Installing dependencies"
echo "[*] Updating system packages..."
apt-get update -q

echo "[*] Installing Docker & dependencies..."
apt-get install -y docker.io docker-compose curl

echo "[*] Enabling Docker service..."
systemctl enable --now docker
echo "[+] Docker is running."

echo "==> File Browser admin setup"
read -rp "[?] Admin username [leave blank for 'admin']: " FB_USER
FB_USER="${FB_USER:-admin}"

read -rsp "[?] Admin password [leave blank for 'admin']: " FB_PASSWORD
echo ""

DEFAULT_PASSWORD=false
if [[ -z "$FB_PASSWORD" ]]; then
    FB_PASSWORD="admin"
    DEFAULT_PASSWORD=true
fi

echo "==> Domain"
read -rp "[?] Domain for File Browser URL (e.g. example.com) [leave blank for localhost]: " FB_DOMAIN
FB_DOMAIN="${FB_DOMAIN:-}"

if [[ -z "$FB_DOMAIN" ]]; then
    NGINX_HINT=false
else
    NGINX_HINT=true
fi

echo "==> Directory setup"
echo "[*] Creating directory structure at $DEPLOY_DIR..."
mkdir -p "$DEPLOY_DIR"/{srv,database,secrets}

chown -R "$FB_UID:$FB_GID" "$DEPLOY_DIR/srv" "$DEPLOY_DIR/database"
echo "[+] Directories created."

echo "[*] Writing secrets..."
printf '%s' "$FB_PASSWORD" > "$DEPLOY_DIR/secrets/filebrowser_admin_password.txt"
chmod 600 "$DEPLOY_DIR/secrets/filebrowser_admin_password.txt"
echo "[+] Secrets saved."

echo "==> Generating configs"

# Note: single-quoted heredoc — no shell expansion inside
cat > "$DEPLOY_DIR/compose.yaml" <<'COMPOSE'
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    restart: unless-stopped
    command:
      - -d
      - /database/filebrowser.db
      - --baseurl
      - /files
    volumes:
      - ./srv:/srv
      - ./database:/database
    ports:
      - "127.0.0.1:8080:80"
    healthcheck:
      test:
        - CMD-SHELL
        - wget -qO- http://localhost/health || exit 1
      interval: 10s
      timeout: 5s
      retries: 6
      start_period: 10s
COMPOSE

echo "[+] Configs written."

echo "==> Database bootstrap"

DB_FILE="$DEPLOY_DIR/database/filebrowser.db"

if [[ -f "$DB_FILE" ]]; then
    echo "[i] Existing database found — skipping admin bootstrap, existing credentials retained."
else
    echo "[*] Pulling File Browser image..."
    docker pull -q filebrowser/filebrowser:latest >/dev/null

    echo "[*] Initializing configuration..."
    # File Browser enforces password length of 12 characters.
    # Validate it here to avoid a failed bootstrap later.
    docker run --rm \
        -v "$DEPLOY_DIR/database:/database" \
        filebrowser/filebrowser:latest \
        config init \
        -d /database/filebrowser.db \
        --address 0.0.0.0 \
        --port 80 \
        -r /srv

    echo "[*] Creating admin user '$FB_USER'..."
    docker run --rm \
        -v "$DEPLOY_DIR/database:/database" \
        filebrowser/filebrowser:latest \
        users add "$FB_USER" "$FB_PASSWORD" \
        --perm.admin \
        -d /database/filebrowser.db
    echo "[+] Admin user created."
fi

echo "==> Starting the stack"
cd "$DEPLOY_DIR"

echo "[*] Pulling images..."
docker compose pull -q

echo "[*] Starting containers..."
docker compose up -d --remove-orphans
echo "[+] Containers started."

echo "==> Waiting for File Browser health"
echo "[*] Polling File Browser (up to 90s)..."
FB_READY=false
for i in $(seq 1 45); do
    if curl -sf http://localhost:8080/health >/dev/null 2>&1; then
        echo "[+] File Browser is healthy."
        FB_READY=true
        break
    fi
    printf "."
    sleep 2
done
echo ""

if [[ "$FB_READY" == false ]]; then
    echo "[WARN] File Browser did not become healthy in time."
    echo "       The container may still be starting."
    echo "       Check status with: docker compose -f $DEPLOY_DIR/compose.yaml ps"
fi

echo ""
docker compose ps

echo ""
echo "==> Summary"
echo ""

if [[ "$DEFAULT_PASSWORD" == true ]]; then
    echo -e "${RED}It looks like the health check timed out.${NC}"
    echo -e "${RED}The service may still become available with the default credentials.${NC}"
    echo -e "${RED}You are using the DEFAULT password: 'admin'${NC}"
    echo -e "${RED}This is EXTREMELY INSECURE.${NC}"
    echo -e "${RED}Change it immediately after first login:${NC}"
    echo -e "${RED}    Settings -> Profile -> Change Password${NC}"
fi

echo ""
echo "Stack info:"
echo "  Deploy dir:     $DEPLOY_DIR"
echo "  Admin user:     $FB_USER"
echo "  File Browser:   http://localhost:8080"
echo ""
echo "Data:"
echo "  Served files:   $DEPLOY_DIR/srv"
echo "  Database:       $DEPLOY_DIR/database/filebrowser.db"
echo ""
echo "Note: the admin password is applied only once, at first bootstrap."
echo "  To change it on a live instance use the File Browser UI, or:"
echo "  docker run --rm -v $DEPLOY_DIR/database:/database filebrowser/filebrowser:latest \\"
echo "    users update $FB_USER --password '<new-password>' -d /database/filebrowser.db"
echo ""

if [[ "$NGINX_HINT" == true ]]; then
    echo   " Nginx reverse proxy block for ${FB_DOMAIN}:"
    echo   " ┌─ Add to your server {} block ──────────────────────────────────┐"
    printf " │  location = /files {\n"
    printf " │      return 301 /files/;\n"
    printf " │  }\n"
    printf " │  location /files/ {\n"
    printf " │      proxy_http_version 1.1;\n"
    printf " │      proxy_set_header Host \$host;\n"
    printf " │      proxy_set_header X-Real-IP \$remote_addr;\n"
    printf " │      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
    printf " │      proxy_set_header X-Forwarded-Proto \$scheme;\n"
    printf " │      proxy_set_header Upgrade \$http_upgrade;\n"
    printf " │      proxy_set_header Connection \"upgrade\";\n"
    printf " │      # Trailing slash strips /files/ prefix before forwarding\n"
    printf " │      proxy_pass http://127.0.0.1:8080/;\n"
    printf " │  }\n"
    echo   " └────────────────────────────────────────────────────────────────┘"
fi
