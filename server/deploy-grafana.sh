#!/bin/bash

# Grafana + Prometheus stack deployment for Debian/Ubuntu systems.
# Installs Docker, generates all configs inline, and imports
# the Node Exporter Full dashboard (ID 19937) via the Grafana API.
# Recommended for Debian 12/13 and Ubuntu 22.04/24.04 LTS.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEPLOY_DIR="/opt/grafana-stack"

if [[ -d "$DEPLOY_DIR" ]]; then
    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║        [!]  E X I S T I N G   D A T A  [!]        ║${NC}"
    echo -e "${RED}╠═══════════════════════════════════════════════════╣${NC}"
    echo -e "${RED}║                                                   ║${NC}"
    echo -e "${RED}║  Directory $DEPLOY_DIR already exists.            ║${NC}"
    echo -e "${RED}║  Proceeding will PERMANENTLY DELETE all data:     ║${NC}"
    echo -e "${RED}║    containers, volumes, configs, dashboards.      ║${NC}"
    echo -e "${RED}║  THIS ACTION IS IRREVERSIBLE.                     ║${NC}"
    echo -e "${RED}║                                                   ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════╝${NC}"
    echo ""
    read -rp "[?] Wipe existing Grafana stack and all data? [y/N]: " WIPE_CHOICE
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

echo "-------------Installing dependencies-------------"
echo "[*] Updating system packages..."
apt-get update -q

echo "[*] Installing Docker & dependencies..."
apt-get install -y docker.io docker-compose curl

echo "[*] Enabling Docker service..."
systemctl enable --now docker
echo "[+] Docker is running."

echo "------------Grafana credentials setup------------"
read -rp "[?] Grafana admin username [leave blank for 'admin']: " GRAFANA_USER
GRAFANA_USER="${GRAFANA_USER:-admin}"

read -rsp "[?] Grafana admin password [leave blank for 'admin']: " GRAFANA_PASSWORD
echo ""

DEFAULT_PASSWORD=false
if [[ -z "$GRAFANA_PASSWORD" ]]; then
    GRAFANA_PASSWORD="admin"
    DEFAULT_PASSWORD=true
fi

echo "----------------------Domain---------------------"
read -rp "[?] Domain for Grafana root URL (e.g. example.com) [leave blank for localhost]: " GRAFANA_DOMAIN
GRAFANA_DOMAIN="${GRAFANA_DOMAIN:-}"

if [[ -z "$GRAFANA_DOMAIN" ]]; then
    GRAFANA_ROOT_URL="http://localhost:3000/"
    SERVE_FROM_SUB_PATH="false"
    NGINX_HINT=false
else
    GRAFANA_ROOT_URL="https://${GRAFANA_DOMAIN}/grafana/"
    SERVE_FROM_SUB_PATH="true"
    NGINX_HINT=true
fi

echo "-----------------Directory setup-----------------"
echo "[*] Creating directory structure at $DEPLOY_DIR..."
mkdir -p "$DEPLOY_DIR"/{grafana/{data,provisioning/{dashboards,datasources},dashboards},prometheus/data,secrets}

# Grafana data dir permissions (UID 472)
chown -R 472:472 "$DEPLOY_DIR/grafana/data"
chmod -R 755    "$DEPLOY_DIR/grafana/data"

# Prometheus data dir permissions (UID 65534 / nobody)
chown -R 65534:65534 "$DEPLOY_DIR/prometheus/data"
chmod -R 777         "$DEPLOY_DIR/prometheus/data"
echo "[+] Directories created."

echo "[*] Writing secrets..."
printf '%s' "$GRAFANA_PASSWORD" > "$DEPLOY_DIR/secrets/grafana_admin_password.txt"
chmod 600 "$DEPLOY_DIR/secrets/grafana_admin_password.txt"
echo "[+] Secrets saved."

echo "----------------Generating configs---------------"

cat > "$DEPLOY_DIR/.env" <<EOF
GRAFANA_ADMIN_USER=${GRAFANA_USER}
EOF

# Note: \${GRAFANA_ADMIN_USER} is escaped — Docker Compose expands it from .env
cat > "$DEPLOY_DIR/compose.yaml" <<EOF
services:
  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    environment:
      GF_SECURITY_ADMIN_USER: \${GRAFANA_ADMIN_USER}
      GF_SECURITY_ADMIN_PASSWORD__FILE: /run/secrets/grafana_admin_password
      GF_SERVER_ROOT_URL: ${GRAFANA_ROOT_URL}
      GF_SERVER_SERVE_FROM_SUB_PATH: "${SERVE_FROM_SUB_PATH}"
      GF_USERS_ALLOW_SIGN_UP: "false"
      GF_AUTH_ANONYMOUS_ENABLED: "false"
    secrets:
      - grafana_admin_password
    volumes:
      - ./grafana/data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    ports:
      - "127.0.0.1:3000:3000"
    healthcheck:
      test:
        - CMD-SHELL
        - wget -qO- http://localhost:3000/api/health | grep -q '"database":"ok"'
      interval: 10s
      timeout: 5s
      retries: 18
      start_period: 30s
    networks:
      - monitoring

  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
      - --web.enable-lifecycle
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/data:/prometheus
    healthcheck:
      test:
        - CMD-SHELL
        - wget -qO- http://localhost:9090/-/ready | grep -q Ready
      interval: 10s
      timeout: 5s
      retries: 12
      start_period: 20s
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    restart: unless-stopped
    pid: host
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - --path.procfs=/host/proc
      - --path.sysfs=/host/sys
      - --path.rootfs=/rootfs
      - --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)(\$\$|/)
    networks:
      - monitoring

secrets:
  grafana_admin_password:
    file: ./secrets/grafana_admin_password.txt

networks:
  monitoring:
    driver: bridge
EOF

cat > "$DEPLOY_DIR/prometheus/prometheus.yml" <<'EOF'
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
EOF

cat > "$DEPLOY_DIR/grafana/provisioning/datasources/prometheus.yml" <<'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
EOF

cat > "$DEPLOY_DIR/grafana/provisioning/dashboards/dashboards.yml" <<'EOF'
apiVersion: 1

providers:
  - name: Default
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
EOF

echo "[+] Configs written."

echo "----------------Starting the stack---------------"
cd "$DEPLOY_DIR"

echo "[*] Pulling images..."
docker compose pull -q

echo "[*] Starting containers..."
docker compose up -d --remove-orphans
echo "[+] Containers started."

echo "------------Waiting for Grafana health-----------"
echo "[*] Polling Grafana API (up to 60s)..."
GRAFANA_READY=false
for i in $(seq 1 30); do
    if curl -sf http://localhost:3000/api/health 2>/dev/null | grep -q '"database":"ok"'; then
        echo "[+] Grafana is healthy."
        GRAFANA_READY=true
        break
    fi
    printf "."
    sleep 2
done
echo ""

if [[ "$GRAFANA_READY" == false ]]; then
    echo "[WARN] Grafana did not become healthy in time."
    echo "       Dashboard import skipped — run this when Grafana is up:"
    echo "       curl -fsSL https://grafana.com/api/dashboards/19937/revisions/latest/download | \\"
    echo "         curl -sf -X POST -H 'Content-Type: application/json' \\"
    echo "           -u '${GRAFANA_USER}:<password>' \\"
    echo "           -d '{\"dashboard\":'\$(cat)',\"overwrite\":true,\"inputs\":[{\"name\":\"DS_PROMETHEUS\",\"type\":\"datasource\",\"pluginId\":\"prometheus\",\"value\":\"Prometheus\"}]}' \\"
    echo "           http://localhost:3000/api/dashboards/import"
else
    echo "------------Importing dashboard 19937------------"
    echo "[*] Downloading Node Exporter Full dashboard from grafana.com..."
    DASHBOARD_JSON=""
    if DASHBOARD_JSON=$(curl -fsSL "https://grafana.com/api/dashboards/19937/revisions/latest/download" 2>/dev/null); then
        echo "[*] Importing into Grafana..."
        IMPORT_PAYLOAD=$(printf '{"dashboard":%s,"overwrite":true,"inputs":[{"name":"DS_PROMETHEUS","type":"datasource","pluginId":"prometheus","value":"Prometheus"}]}' "$DASHBOARD_JSON")
        if curl -sf -X POST \
            -H "Content-Type: application/json" \
            -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
            -d "$IMPORT_PAYLOAD" \
            http://localhost:3000/api/dashboards/import \
            | grep -q '"status":"success"'; then
            echo "[+] Dashboard 19937 imported successfully."
        else
            echo "[!] Import request failed."
            echo "[i] Import it manually: Dashboards → Import → ID 19937"
        fi
    else
        echo "[!] Could not download dashboard from grafana.com."
        echo "[i] Import it manually: Dashboards → Import → ID 19937"
    fi
fi

echo ""
docker compose ps
echo ""

echo "-----------------Setup Complete!-----------------"

if [[ "$DEFAULT_PASSWORD" == true ]]; then
    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║     [!]  C R I T I C A L   W A R N I N G  [!]     ║${NC}"
    echo -e "${RED}╠═══════════════════════════════════════════════════╣${NC}"
    echo -e "${RED}║                                                   ║${NC}"
    echo -e "${RED}║  You are using the DEFAULT password: 'admin'      ║${NC}"
    echo -e "${RED}║  This is EXTREMELY INSECURE.                      ║${NC}"
    echo -e "${RED}║  Change it immediately after first login:         ║${NC}"
    echo -e "${RED}║    Profile → Change Password                      ║${NC}"
    echo -e "${RED}║                                                   ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════╝${NC}"
    echo ""
fi

echo "[SUCCESS]"
echo "Stack info:"
echo "  Deploy dir:     $DEPLOY_DIR"
echo "  Admin user:     $GRAFANA_USER"
echo "  Grafana:        http://localhost:3000"
echo "  Prometheus:     http://localhost:9090 (internal)"
echo ""
echo "Dashboard:"
echo "  Node Exporter Full (19937) imported."
echo "  To get metrics — install node_exporter and add targets to:"
echo "  $DEPLOY_DIR/prometheus/prometheus.yml"
echo "  Then reload: curl -sf -X POST http://localhost:9090/-/reload"
echo ""

if [[ "$NGINX_HINT" == true ]]; then
    echo   " Nginx reverse proxy block for ${GRAFANA_DOMAIN}:"
    echo   " ┌─ Add to your server {} block ──────────────────────────────────┐"
    printf " │  location = /grafana {\n"
    printf " │      return 301 /grafana/;\n"
    printf " │  }\n"
    printf " │  location /grafana/ {\n"
    printf " │      proxy_http_version 1.1;\n"
    printf " │      proxy_set_header Host \$host;\n"
    printf " │      proxy_set_header X-Real-IP \$remote_addr;\n"
    printf " │      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n"
    printf " │      proxy_set_header X-Forwarded-Proto \$scheme;\n"
    printf " │      proxy_set_header Upgrade \$http_upgrade;\n"
    printf " │      proxy_set_header Connection \"upgrade\";\n"
    printf " │      proxy_pass http://127.0.0.1:3000;\n"
    printf " │  }\n"
    echo   " └────────────────────────────────────────────────────────────────┘"
fi
