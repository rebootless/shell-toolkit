#!/bin/bash

# Full server deployment workflow for Debian/Ubuntu.
# Sources .env from the same directory and runs four scripts in sequence:
#   server-bootstrap.sh → deploy-nginx.sh → deploy-grafana.sh → deploy-portainer.sh
# Answers are piped to each script via stdin using printf — safely handles
# special characters in values. Fresh deployments only — re-running on an
# existing setup breaks prompt ordering.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Prevent apt from swallowing stdin inputs during printf piping
export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(cd "$SCRIPT_DIR/../server" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

# .env check
if [[ ! -f "$ENV_FILE" ]]; then
    echo "[!] Config not found: $ENV_FILE"
    echo "[i] cp $SCRIPT_DIR/.env.example $ENV_FILE && nano $ENV_FILE"
    exit 1
fi

source "$ENV_FILE"

# ── Validate: all required variables are declared ─────────────────────────────
MISSING=0
for var in \
    BOOTSTRAP_PROFILE BOOTSTRAP_FIREWALL BOOTSTRAP_FAIL2BAN \
    CREATE_DEPLOY_USER DEPLOY_USER DEPLOY_USER_PASSWORD \
    NGINX_AVAHI NGINX_PHP NGINX_GRAFANA_PROXY NGINX_PORTAINER_PROXY \
    NGINX_FIREWALL NGINX_DOMAIN \
    GRAFANA_USER GRAFANA_PASSWORD GRAFANA_DOMAIN \
    PORTAINER_PASSWORD PORTAINER_DOMAIN
do
    if ! declare -p "$var" &>/dev/null; then
        echo "[!] Not defined in .env: $var"
        MISSING=1
    fi
done
if [[ $MISSING -eq 1 ]]; then
    echo "[!] Fix .env and retry."
    exit 1
fi

# ── Validate: specific required values ───────────────────────────────────────

# BOOTSTRAP_PROFILE must be 1 or 2 — 0 exits the subscript cleanly (exit 0),
# which set -e treats as success, silently skipping bootstrap entirely.
if [[ ! "$BOOTSTRAP_PROFILE" =~ ^[12]$ ]]; then
    echo "[!] BOOTSTRAP_PROFILE must be 1 or 2, got: '${BOOTSTRAP_PROFILE:-<empty>}'"
    exit 1
fi

if [[ "${CREATE_DEPLOY_USER,,}" =~ ^y ]]; then
    if [[ -z "$DEPLOY_USER" ]]; then
        echo "[!] CREATE_DEPLOY_USER=y but DEPLOY_USER is empty."
        echo "[i] Set a username or set CREATE_DEPLOY_USER=n."
        exit 1
    fi
    # chpasswd format is 'user:pass' — a colon in the password breaks parsing
    if [[ "$DEPLOY_USER_PASSWORD" == *:* ]]; then
        echo "[!] DEPLOY_USER_PASSWORD must not contain ':' (chpasswd limitation)."
        exit 1
    fi
fi

# ── Script presence check ─────────────────────────────────────────────────────
for s in server-bootstrap.sh deploy-nginx.sh deploy-grafana.sh deploy-portainer.sh; do
    if [[ ! -f "$SERVER_DIR/$s" ]]; then
        echo "[!] Missing: $SERVER_DIR/$s"
        exit 1
    fi
    chmod +x "$SERVER_DIR/$s"
done

# ── Deployment plan ───────────────────────────────────────────────────────────
LOCAL_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo "unknown")
DISPLAY_HOST="${NGINX_DOMAIN:-${LOCAL_IP} (auto)}"

echo "Config:  $ENV_FILE"
echo "Scripts: $SERVER_DIR"
echo ""
echo "1. server-bootstrap.sh"
echo "profile=$BOOTSTRAP_PROFILE  firewall=$BOOTSTRAP_FIREWALL  fail2ban=$BOOTSTRAP_FAIL2BAN"
if [[ "${CREATE_DEPLOY_USER,,}" =~ ^y ]]; then
    echo "deploy user: $DEPLOY_USER (password: ${DEPLOY_USER_PASSWORD:+[set]}${DEPLOY_USER_PASSWORD:-[blank]})"
else
    echo "deploy user: [skipped]"
fi
echo ""
echo "2. deploy-nginx.sh"
echo "domain=${NGINX_DOMAIN:-[auto: $LOCAL_IP]}  php=$NGINX_PHP  avahi=$NGINX_AVAHI"
echo "grafana-proxy=$NGINX_GRAFANA_PROXY  portainer-proxy=$NGINX_PORTAINER_PROXY  firewall=$NGINX_FIREWALL"
echo ""
echo "3. deploy-grafana.sh"
echo "user=${GRAFANA_USER:-[default: admin]}  password=${GRAFANA_PASSWORD:+[set]}${GRAFANA_PASSWORD:-[default: admin]}  domain=${GRAFANA_DOMAIN:-[default: localhost]}"
echo ""
echo "4. deploy-portainer.sh"
echo "password=${PORTAINER_PASSWORD:+[set]}${PORTAINER_PASSWORD:-[default: admin]}  domain=${PORTAINER_DOMAIN:-[default: localhost]}"
echo ""
echo "Fresh deployments only."
echo ""
read -rp "[?] Start? [y/N]: " PROCEED
[[ "${PROCEED,,}" =~ ^y ]] || { echo "[i] Aborted."; exit 0; }

# ── Step runner ───────────────────────────────────────────────────────────────
STEP=0
trap 'echo "[!] Failed at step $STEP/4."; exit 1' ERR

step() {
    STEP=$((STEP + 1))
    echo ""
    echo "Step $STEP/4: $1"
    echo ""
}

# Step 1 — stdin order: profile, user-index (0=skip), firewall, fail2ban
# printf '%s\n' is used throughout instead of heredoc <<EOF — it passes values
# as literal strings without shell expansion, preventing issues with special
# characters (e.g. $ in passwords) that <<EOF would attempt to expand.
step "server-bootstrap.sh"
printf '%s\n' \
    "$BOOTSTRAP_PROFILE" \
    "0" \
    "$BOOTSTRAP_FIREWALL" \
    "$BOOTSTRAP_FAIL2BAN" \
    | bash "$SERVER_DIR/server-bootstrap.sh"

# Sudo user creation — driven by .env, handled here instead of inside bootstrap
if [[ "${CREATE_DEPLOY_USER,,}" =~ ^y ]]; then
    echo ""
    echo "[*] Handling sudo user configuration for '$DEPLOY_USER'..."

    if id "$DEPLOY_USER" &>/dev/null; then
        echo "[i] User '$DEPLOY_USER' already exists."
    else
        echo "[+] Creating new user '$DEPLOY_USER'..."
        adduser --disabled-password --gecos "" "$DEPLOY_USER"

        if [[ -n "$DEPLOY_USER_PASSWORD" ]]; then
            # printf avoids chpasswd treating extra colons in the string as delimiters
            printf '%s:%s\n' "$DEPLOY_USER" "$DEPLOY_USER_PASSWORD" | chpasswd
            echo "[+] Password set for '$DEPLOY_USER'."
        else
            echo "[!] Warning: DEPLOY_USER_PASSWORD is empty — user has no password set."
        fi
    fi

    if getent group sudo >/dev/null; then
        usermod -aG sudo "$DEPLOY_USER"
        echo "[+] User '$DEPLOY_USER' added to 'sudo' group."
    else
        echo "[!] Warning: 'sudo' group not found."
    fi
fi

# Step 2 — stdin order: avahi, php, grafana-proxy, portainer-proxy, firewall, domain
step "deploy-nginx.sh"
printf '%s\n' \
    "$NGINX_AVAHI" \
    "$NGINX_PHP" \
    "$NGINX_GRAFANA_PROXY" \
    "$NGINX_PORTAINER_PROXY" \
    "$NGINX_FIREWALL" \
    "$NGINX_DOMAIN" \
    | bash "$SERVER_DIR/deploy-nginx.sh"

# Step 3 — stdin order: username, password, domain
step "deploy-grafana.sh"
printf '%s\n' \
    "$GRAFANA_USER" \
    "$GRAFANA_PASSWORD" \
    "$GRAFANA_DOMAIN" \
    | bash "$SERVER_DIR/deploy-grafana.sh"

# Step 4 — stdin order: password, domain
step "deploy-portainer.sh"
printf '%s\n' \
    "$PORTAINER_PASSWORD" \
    "$PORTAINER_DOMAIN" \
    | bash "$SERVER_DIR/deploy-portainer.sh"

trap - ERR

echo ""
echo "================================================="
echo "[+] Deployment complete."
echo ""
echo "  Nginx:      http://$DISPLAY_HOST"
echo "  Grafana:    http://$DISPLAY_HOST/grafana"
echo "  Portainer:  http://$DISPLAY_HOST/portainer"
echo "  Prometheus: http://localhost:9090 (internal)"
echo ""

if [[ "${CREATE_DEPLOY_USER,,}" =~ ^y ]]; then
    echo "  Sudo User:  $DEPLOY_USER"
    echo ""
fi

echo "  /var/log/nginx/"
echo "  docker compose -f /opt/grafana-stack/compose.yaml logs"
echo "  docker compose -f /opt/portainer-stack/compose.yaml logs"
echo ""
