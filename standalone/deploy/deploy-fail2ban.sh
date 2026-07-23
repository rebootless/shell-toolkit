#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Installing dependencies"

echo "[*] Updating package index..."
apt-get update

echo "[*] Installing Fail2Ban..."
apt-get install -y fail2ban

echo ""
echo "==> Configuring Fail2Ban"

cat >/etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
backend = systemd
EOF

echo ""
echo "==> Validation"

if fail2ban-client -t >/dev/null 2>&1; then
    echo "[+] Fail2Ban configuration is valid."
else
    echo "[!] Fail2Ban configuration is invalid."
    exit 1
fi

echo "[*] Enabling Fail2Ban service..."
systemctl enable fail2ban

echo "[*] Restarting Fail2Ban service..."
systemctl restart fail2ban

echo "[*] Waiting for Fail2Ban..."

for _ in {1..50}; do
    [[ -S /run/fail2ban/fail2ban.sock ]] && break
    sleep 0.2
done

if [[ ! -S /run/fail2ban/fail2ban.sock ]]; then
    echo "[!] Fail2Ban socket was not created."
    journalctl -u fail2ban --no-pager -n 30
    exit 1
fi

for _ in {1..50}; do
    if fail2ban-client ping >/dev/null 2>&1; then
        break
    fi
    sleep 0.2
done

if ! fail2ban-client ping >/dev/null 2>&1; then
    echo "[!] Fail2Ban failed to become ready."
    journalctl -u fail2ban --no-pager -n 30
    exit 1
fi

FAIL2BAN_STATUS=$(systemctl is-active fail2ban)
FAIL2BAN_ENABLED=$(systemctl is-enabled fail2ban)

echo ""
echo "==> Summary"
echo ""
echo "Fail2Ban Information:"
echo "  Service:          fail2ban"
echo "  Status:           $FAIL2BAN_STATUS"
echo "  Startup:          $FAIL2BAN_ENABLED"
echo "  Config:           /etc/fail2ban/jail.local"
echo ""

echo "Active Jails:"
fail2ban-client status

echo ""
echo "[+] Fail2Ban deployed successfully."
