#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
    exit 1
fi

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEPLOY_DIR="/opt/portainer-stack"

if [[ -d "$DEPLOY_DIR" ]]; then
    echo ""
    echo -e "${RED}Directory $DEPLOY_DIR already exists.${NC}"
    echo -e "${RED}Proceeding will PERMANENTLY DELETE all data:${NC}"
    echo -e "${RED}  containers, volumes, configs, Portainer DB.${NC}"
    echo -e "${RED}THIS ACTION IS IRREVERSIBLE.${NC}"
    echo ""
    read -rp "Wipe existing Portainer stack and all data? [y/N]: " WIPE_CHOICE
    if [[ "${WIPE_CHOICE,,}" =~ ^y ]]; then
        read -rp "Are you sure? This cannot be undone. Type 'yes' to confirm: " WIPE_CONFIRM
        if [[ "$WIPE_CONFIRM" == "yes" ]]; then
            echo "Stopping and removing containers..."
            if [[ -f "$DEPLOY_DIR/compose.yaml" ]]; then
                docker compose -f "$DEPLOY_DIR/compose.yaml" down -v 2>/dev/null || true
            fi
            echo "Deleting $DEPLOY_DIR..."
            rm -rf "$DEPLOY_DIR"
            echo "Wiped."
        else
            echo "Confirmation not received — aborting."
            exit 0
        fi
    else
        echo "Wipe skipped — continuing with existing data."
    fi
fi

echo ""
echo "==> Installing dependencies"

echo "Updating system packages..."
apt-get update -q

echo "Installing Docker & dependencies..."
apt-get install -y docker.io docker-compose curl

echo "Enabling Docker service..."
systemctl enable --now docker
echo "Docker is running."

echo "==> Portainer credentials setup"
# Portainer CE's built-in admin account is always named 'admin'.
# The --admin-password-file flag sets the password for this account on first run.
echo "NOTE: Portainer CE admin username is always 'admin'."

read -rsp "Portainer admin password [leave blank for 'admin']: " PORTAINER_PASSWORD

DEFAULT_PASSWORD=false
if [[ -z "$PORTAINER_PASSWORD" ]]; then
    PORTAINER_PASSWORD="admin"
    DEFAULT_PASSWORD=true
fi

echo ""
echo "==> Domain"
read -rp "Domain for Portainer URL (e.g. example.com) [leave blank for localhost]: " PORTAINER_DOMAIN
PORTAINER_DOMAIN="${PORTAINER_DOMAIN:-}"

if [[ -z "$PORTAINER_DOMAIN" ]]; then
    NGINX_HINT=false
else
    NGINX_HINT=true
fi

echo ""
echo "==> Directory setup"

echo "Creating directory structure at $DEPLOY_DIR..."
mkdir -p "$DEPLOY_DIR"/{data,secrets}
echo "Directories created."

echo "Writing secrets..."
printf '%s' "$PORTAINER_PASSWORD" > "$DEPLOY_DIR/secrets/portainer_admin_password.txt"
chmod 600 "$DEPLOY_DIR/secrets/portainer_admin_password.txt"
echo "Secrets saved."

echo ""
echo "==> Generating configs"

# Portainer: 2.39.5 (no "v" prefix)
cat > "$DEPLOY_DIR/compose.yaml" <<'COMPOSE'
services:
  portainer:
    image: portainer/portainer-ce:2.39.5
    restart: unless-stopped
    command:
      # Load admin password from Docker secret (applied on first run only)
      - --admin-password-file=/run/secrets/portainer_admin_password
    secrets:
      - portainer_admin_password
    volumes:
      # Docker socket gives Portainer access to manage containers on this host
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/data
    ports:
      # Bind only to loopback — expose via nginx reverse proxy
      - "127.0.0.1:9000:9000"
    healthcheck:
      test:
        - CMD-SHELL
        - wget -qO- http://localhost:9000/api/status | grep -q '"Version"'
      interval: 10s
      timeout: 5s
      retries: 30
      start_period: 60s

secrets:
  portainer_admin_password:
    file: ./secrets/portainer_admin_password.txt
COMPOSE

echo "Configs written."

echo ""
echo "==> Starting the stack"
cd "$DEPLOY_DIR"

echo "Pulling images..."
docker compose pull -q

echo "Starting containers..."
docker compose up -d --remove-orphans
echo "Containers started."

echo ""
echo "==> Waiting for Portainer health"
echo "Polling Portainer API (up to 300s)..."
PORTAINER_READY=false
for i in $(seq 1 300); do
    if curl -sf http://localhost:9000/api/status 2>/dev/null | grep -q '"Version"'; then
        echo "Portainer is healthy."
        PORTAINER_READY=true
        break
    fi
    printf "."
    sleep 1
done

echo ""
if [[ "$PORTAINER_READY" == false ]]; then
    echo "[WARN] Portainer did not become healthy within 300 seconds."
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
    echo -e "${RED}    My Account -> Change Password${NC}"
fi

echo ""
echo "Stack info:"
echo "  Deploy dir:     $DEPLOY_DIR"
echo "  Admin user:     admin"
echo "  Portainer:      http://localhost:9000"

echo ""
echo "Data:"
echo "  Portainer data: $DEPLOY_DIR/data"
echo "  Docker socket:  /var/run/docker.sock (mounted read-write)"

echo ""
echo "Note: --admin-password-file applies only on first run."
echo "  To change the password on a live instance use the Portainer UI."

echo ""
if [[ "$NGINX_HINT" == true ]]; then
    echo   " Nginx reverse proxy block for ${PORTAINER_DOMAIN}:"
    echo   " ┌─ Add to your server {} block ──────────────────────────────────┐"
    printf " │  location = /portainer {\n"
    printf " │      return 301 /portainer/;\n"
    printf " │  }\n"
    printf " │  location /portainer/ {\n"
    printf " │      proxy_http_version 1.1;\n"
    printf " │      proxy_set_header Host \$host;\n"
    printf " │      proxy_set_header X-Real-IP \$remote_addr;\n"
    printf " │      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
    printf " │      proxy_set_header X-Forwarded-Proto \$scheme;\n"
    printf " │      proxy_set_header Upgrade \$http_upgrade;\n"
    printf " │      proxy_set_header Connection \"upgrade\";\n"
    printf " │      # Trailing slash strips /portainer/ prefix before forwarding\n"
    printf " │      proxy_pass http://127.0.0.1:9000/;\n"
    printf " │  }\n"
    echo   " └────────────────────────────────────────────────────────────────┘"
fi
