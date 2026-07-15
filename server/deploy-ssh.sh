#!/bin/bash

# OpenSSH deployment for Debian/Ubuntu systems.
# Installs OpenSSH Server, enables the service,
# and can configure firewalld for SSH access.
# Recommended for Debian 12/13 and Ubuntu 22.04/24.04 LTS.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "-------------Installing dependencies-------------"

echo "[*] Updating system packages..."
apt-get update

echo "[*] Installing OpenSSH Server..."
apt-get install -y openssh-server

echo "[*] Enabling and starting SSH service..."
systemctl enable --now ssh

echo "-----------------Firewall setup------------------"

FIREWALL_ENABLED="n"

read -rp "[?] Install Firewalld? [y/N]: " FIREWALL_CHOICE

case "${FIREWALL_CHOICE,,}" in
    y|yes)
        echo "[*] Installing and configuring firewalld..."

        if apt-get install -y firewalld; then
            systemctl enable --now firewalld

            firewall-cmd --permanent --zone=public --add-service=ssh
            firewall-cmd --set-default-zone=public
            firewall-cmd --reload

            FIREWALL_ENABLED="y"

            echo "[i] Active firewalld services:"
            firewall-cmd --zone=public --list-services
        else
            echo "[!] Failed to install firewalld."
        fi
        ;;
    n|no|"")
        echo "[i] Firewalld setup skipped."
        ;;
    *)
        echo "[!] Invalid input -> skipping firewalld setup..."
        ;;
esac

echo "------------------SSH validation-----------------"

if sshd -t; then
    echo "[+] SSH configuration is valid."
else
    echo "//////////////////////////////////////////////////"
    echo "Configuration error found."
    echo "SSH service was NOT restarted."
    echo "//////////////////////////////////////////////////"
    exit 1
fi

systemctl restart ssh

SSH_STATUS=$(systemctl is-active ssh)
SSH_ENABLED=$(systemctl is-enabled ssh)

echo "------------------Setup Complete!----------------"

echo "SSH Information:"
echo "  Service:          ssh"
echo "  Status:           $SSH_STATUS"
echo "  Startup:          $SSH_ENABLED"
echo "  Config:           /etc/ssh/sshd_config"
echo ""

echo "Security & Firewall:"
if [[ "$FIREWALL_ENABLED" == "y" ]]; then
    echo "  Firewall:         Firewalld (SSH allowed)"
else
    echo "  Firewall:         NOT CONFIGURED (Warning: SSH may be blocked)"
fi
echo ""

echo "Connect using:"
echo "  >> ssh <username>@<server-ip>"
