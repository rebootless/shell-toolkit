#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/../../standalone/install/apt/cli" && pwd)"
MAINTENANCE_DIR="$(cd "$SCRIPT_DIR/../../standalone/maintenance" && pwd)"
GROUPS_DIR="$(cd "$SCRIPT_DIR/../../standalone/groups" && pwd)"
DEPLOY_DIR="$(cd "$SCRIPT_DIR/../../standalone/deploy" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "[INFO] Config not found: $ENV_FILE"
    echo "    cp $SCRIPT_DIR/.env.example $ENV_FILE && nano $ENV_FILE"
    exit 1
fi

source "$ENV_FILE"

# is_yes VAR — true if the variable named VAR is (case-insensitively) "y".
# Used instead of chained `[[ ]] &&` so callers stay set -e safe: bash
# exempts a function's return status from set -e when it's an if-condition.
is_yes() {
    local v="${!1:-}"
    [[ "${v,,}" == "y" ]]
}

STEP_TOGGLES=(
    DEPLOY_FIREWALL DEPLOY_SSH DEPLOY_FAIL2BAN CREATE_DEPLOY_USER
    DEPLOY_NGINX DEPLOY_GRAFANA DEPLOY_PORTAINER DEPLOY_FILEBROWSER
)

MISSING=0
for var in "${STEP_TOGGLES[@]}"; do
    if ! declare -p "$var" &>/dev/null; then
        echo "[!] Not defined in .env: $var"
        MISSING=1
    fi
done
if [[ $MISSING -eq 1 ]]; then
    echo "[!] Fix .env and retry."
    exit 1
fi

for var in "${STEP_TOGGLES[@]}"; do
    val="${!var}"
    if [[ ! "${val,,}" =~ ^(y|n)$ ]]; then
        echo "[!] $var must be 'y' or 'n', got: '${val:-<empty>}'"
        exit 1
    fi
done

check_vars() {
    for var in "$@"; do
        if ! declare -p "$var" &>/dev/null; then
            echo "[!] Not defined in .env: $var"
            MISSING=1
        fi
    done
}

MISSING=0
if is_yes DEPLOY_SSH; then
    check_vars SSH_ALLOW_FIREWALL
fi
if is_yes CREATE_DEPLOY_USER; then
    check_vars DEPLOY_USER DEPLOY_USER_PASSWORD
fi
if is_yes DEPLOY_NGINX; then
    check_vars NGINX_AVAHI NGINX_PHP NGINX_GRAFANA_PROXY NGINX_PORTAINER_PROXY \
        NGINX_FILEBROWSER_PROXY NGINX_FIREWALL NGINX_DOMAIN
fi
if is_yes DEPLOY_GRAFANA; then
    check_vars GRAFANA_USER GRAFANA_PASSWORD GRAFANA_DOMAIN
fi
if is_yes DEPLOY_PORTAINER; then
    check_vars PORTAINER_PASSWORD PORTAINER_DOMAIN
fi
if is_yes DEPLOY_FILEBROWSER; then
    check_vars FILEBROWSER_USER FILEBROWSER_PASSWORD FILEBROWSER_DOMAIN
fi
if [[ $MISSING -eq 1 ]]; then
    echo "[!] Fix .env and retry."
    exit 1
fi

# Deploy-user value constraints (chpasswd uses "user:password" internally,
# so a literal ':' in the password would corrupt the create-user.sh input).
if is_yes CREATE_DEPLOY_USER; then
    if [[ -z "$DEPLOY_USER" ]]; then
        echo "[!] DEPLOY_USER cannot be empty."
        exit 1
    fi
    if [[ "$DEPLOY_USER_PASSWORD" == *:* ]]; then
        echo "[!] DEPLOY_USER_PASSWORD must not contain ':'."
        exit 1
    fi
fi

require_script() {
    if [[ ! -f "$1" ]]; then
        echo "[!] Missing: $1"
        exit 1
    fi
    chmod +x "$1"
}

if is_yes DEPLOY_FIREWALL; then require_script "$INSTALL_DIR/install-firewalld-cli.sh"; fi
if is_yes DEPLOY_SSH; then require_script "$DEPLOY_DIR/deploy-ssh.sh"; fi
if is_yes DEPLOY_FAIL2BAN; then require_script "$DEPLOY_DIR/deploy-fail2ban.sh"; fi
if is_yes CREATE_DEPLOY_USER; then
    require_script "$MAINTENANCE_DIR/create-user.sh"
    require_script "$GROUPS_DIR/grant-sudo.sh"
fi
if is_yes DEPLOY_NGINX; then require_script "$DEPLOY_DIR/deploy-nginx.sh"; fi
if is_yes DEPLOY_GRAFANA; then require_script "$DEPLOY_DIR/deploy-grafana.sh"; fi
if is_yes DEPLOY_PORTAINER; then require_script "$DEPLOY_DIR/deploy-portainer.sh"; fi
if is_yes DEPLOY_FILEBROWSER; then require_script "$DEPLOY_DIR/deploy-filebrowser.sh"; fi

if is_yes DEPLOY_NGINX; then
    if [[ "${NGINX_GRAFANA_PROXY,,}" == "y" ]] && ! is_yes DEPLOY_GRAFANA; then
        echo "[!] Warning: NGINX_GRAFANA_PROXY=y but DEPLOY_GRAFANA=n — the /grafana proxy will point to a service not deployed by this run."
    fi
    if [[ "${NGINX_PORTAINER_PROXY,,}" == "y" ]] && ! is_yes DEPLOY_PORTAINER; then
        echo "[!] Warning: NGINX_PORTAINER_PROXY=y but DEPLOY_PORTAINER=n — the /portainer proxy will point to a service not deployed by this run."
    fi
    if [[ "${NGINX_FILEBROWSER_PROXY,,}" == "y" ]] && ! is_yes DEPLOY_FILEBROWSER; then
        echo "[!] Warning: NGINX_FILEBROWSER_PROXY=y but DEPLOY_FILEBROWSER=n — the /files proxy will point to a service not deployed by this run."
    fi
fi

TOTAL_STEPS=0
for var in "${STEP_TOGGLES[@]}"; do
    if is_yes "$var"; then
        TOTAL_STEPS=$((TOTAL_STEPS + 1))
    fi
done

if [[ $TOTAL_STEPS -eq 0 ]]; then
    echo "[!] Every step is disabled (all DEPLOY_*/CREATE_* toggles are 'n') — nothing to do."
    exit 1
fi

echo "Config:  $ENV_FILE"
echo "Scripts: $DEPLOY_DIR"
echo ""

N=0
if is_yes DEPLOY_FIREWALL; then
    N=$((N + 1)); echo "$N. install-firewalld-cli.sh"
fi
if is_yes DEPLOY_SSH; then
    N=$((N + 1)); echo "$N. deploy-ssh.sh          allow_firewall=$SSH_ALLOW_FIREWALL"
fi
if is_yes DEPLOY_FAIL2BAN; then
    N=$((N + 1)); echo "$N. deploy-fail2ban.sh"
fi
if is_yes CREATE_DEPLOY_USER; then
    N=$((N + 1)); echo "$N. create-user.sh + grant-sudo.sh   user=$DEPLOY_USER"
fi
if is_yes DEPLOY_NGINX; then
    N=$((N + 1)); echo "$N. deploy-nginx.sh        avahi=$NGINX_AVAHI php=$NGINX_PHP grafana_proxy=$NGINX_GRAFANA_PROXY portainer_proxy=$NGINX_PORTAINER_PROXY filebrowser_proxy=$NGINX_FILEBROWSER_PROXY firewall=$NGINX_FIREWALL domain=$NGINX_DOMAIN"
fi
if is_yes DEPLOY_GRAFANA; then
    N=$((N + 1)); echo "$N. deploy-grafana.sh      user=$GRAFANA_USER domain=$GRAFANA_DOMAIN"
fi
if is_yes DEPLOY_PORTAINER; then
    N=$((N + 1)); echo "$N. deploy-portainer.sh    domain=$PORTAINER_DOMAIN"
fi
if is_yes DEPLOY_FILEBROWSER; then
    N=$((N + 1)); echo "$N. deploy-filebrowser.sh  user=$FILEBROWSER_USER domain=$FILEBROWSER_DOMAIN"
fi
echo ""

read -rp "[?] Start? [y/N]: " PROCEED
[[ "${PROCEED,,}" =~ ^y ]] || { echo "[i] Aborted."; exit 0; }

STEP=0
trap 'echo "[!] Failed at step $STEP/$TOTAL_STEPS."; exit 1' ERR

step() {
    STEP=$((STEP + 1))
    echo ""
    echo "Step $STEP/$TOTAL_STEPS: $1"
    echo ""
}

if is_yes DEPLOY_FIREWALL; then
    step "install-firewalld-cli.sh"
    bash "$INSTALL_DIR/install-firewalld-cli.sh"
fi

if is_yes DEPLOY_SSH; then
    # stdin order: firewall-allow (only read if firewalld is detected installed)
    step "deploy-ssh.sh"
    printf '%s\n' \
        "$SSH_ALLOW_FIREWALL" \
        | bash "$DEPLOY_DIR/deploy-ssh.sh"
fi

if is_yes DEPLOY_FAIL2BAN; then
    step "deploy-fail2ban.sh"
    bash "$DEPLOY_DIR/deploy-fail2ban.sh"
fi

if is_yes CREATE_DEPLOY_USER; then
    # stdin order: create-user.sh (username, password), grant-sudo.sh (username)
    step "create-user.sh + grant-sudo.sh"
    printf '%s\n' \
        "$DEPLOY_USER" \
        "$DEPLOY_USER_PASSWORD" \
        | bash "$MAINTENANCE_DIR/create-user.sh"
    printf '%s\n' \
        "$DEPLOY_USER" \
        | bash "$GROUPS_DIR/grant-sudo.sh"
fi

if is_yes DEPLOY_NGINX; then
    # stdin order: avahi, php, grafana-proxy, portainer-proxy, filebrowser-proxy, firewall, domain
    step "deploy-nginx.sh"
    printf '%s\n' \
        "$NGINX_AVAHI" \
        "$NGINX_PHP" \
        "$NGINX_GRAFANA_PROXY" \
        "$NGINX_PORTAINER_PROXY" \
        "$NGINX_FILEBROWSER_PROXY" \
        "$NGINX_FIREWALL" \
        "$NGINX_DOMAIN" \
        | bash "$DEPLOY_DIR/deploy-nginx.sh"
fi

if is_yes DEPLOY_GRAFANA; then
    # stdin order: user, password, domain
    step "deploy-grafana.sh"
    printf '%s\n' \
        "$GRAFANA_USER" \
        "$GRAFANA_PASSWORD" \
        "$GRAFANA_DOMAIN" \
        | bash "$DEPLOY_DIR/deploy-grafana.sh"
fi

if is_yes DEPLOY_PORTAINER; then
    # stdin order: password, domain
    step "deploy-portainer.sh"
    printf '%s\n' \
        "$PORTAINER_PASSWORD" \
        "$PORTAINER_DOMAIN" \
        | bash "$DEPLOY_DIR/deploy-portainer.sh"
fi

if is_yes DEPLOY_FILEBROWSER; then
    # stdin order: user, password, domain
    step "deploy-filebrowser.sh"
    printf '%s\n' \
        "$FILEBROWSER_USER" \
        "$FILEBROWSER_PASSWORD" \
        "$FILEBROWSER_DOMAIN" \
        | bash "$DEPLOY_DIR/deploy-filebrowser.sh"
fi

trap - ERR

echo ""
echo "==> Summary"
echo ""
echo "Deployed steps:"
if is_yes DEPLOY_FIREWALL; then echo "  [+] Firewalld"; fi
if is_yes DEPLOY_SSH; then echo "  [+] SSH hardening"; fi
if is_yes DEPLOY_FAIL2BAN; then echo "  [+] Fail2Ban"; fi
if is_yes CREATE_DEPLOY_USER; then echo "  [+] Deploy user:  $DEPLOY_USER (sudo)"; fi
if is_yes DEPLOY_NGINX; then echo "  [+] Nginx:         http://$NGINX_DOMAIN"; fi
if is_yes DEPLOY_GRAFANA; then echo "  [+] Grafana:       http://$GRAFANA_DOMAIN:3000"; fi
if is_yes DEPLOY_PORTAINER; then echo "  [+] Portainer:     https://$PORTAINER_DOMAIN:9443"; fi
if is_yes DEPLOY_FILEBROWSER; then echo "  [+] File Browser:  http://$FILEBROWSER_DOMAIN:8080"; fi
