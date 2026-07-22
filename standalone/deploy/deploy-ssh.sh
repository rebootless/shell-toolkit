#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

echo "==> Installing dependencies"

echo "[*] Updating system packages..."
apt-get update

echo "[*] Installing OpenSSH Server..."
apt-get install -y openssh-server

echo "==> Configuring OpenSSH"

echo "[*] Enabling SSH service..."
systemctl enable ssh

echo "==> Firewall"

FIREWALL_ENABLED="n"

if command -v firewall-cmd >/dev/null 2>&1; then

    if systemctl is-active --quiet firewalld; then

        read -rp "[?] Allow SSH through Firewalld? [y/N]: " FIREWALL_CHOICE

        case "${FIREWALL_CHOICE,,}" in
            y|yes)
                echo "[*] Allowing SSH service..."

                firewall-cmd --permanent --zone=public --add-service=ssh
                firewall-cmd --reload

                FIREWALL_ENABLED="y"

                echo "[i] Active firewalld services:"
                firewall-cmd --zone=public --list-services
                ;;
            n|no|"")
                echo "[i] Firewall configuration skipped."
                ;;
            *)
                echo "[!] Invalid input -> skipping firewall configuration."
                ;;
        esac

    else
        echo "[i] Firewalld is installed but not running."
    fi

else
    echo "[i] Firewalld is not installed."
fi

echo "==> Validation"

if sshd -t; then
    echo "[+] SSH configuration is valid."
else
    echo "//////////////////////////////////////////////////"
    echo "Configuration error found."
    echo "SSH service was NOT restarted."
    echo "//////////////////////////////////////////////////"
    exit 1
fi

echo "[*] Restarting SSH service..."
systemctl restart ssh

SSH_STATUS=$(systemctl is-active ssh)
SSH_ENABLED=$(systemctl is-enabled ssh)

echo ""
echo "==> Summary"
echo ""
echo "OpenSSH Information:"
echo "  Service:          ssh"
echo "  Status:           $SSH_STATUS"
echo "  Startup:          $SSH_ENABLED"
echo "  Config:           /etc/ssh/sshd_config"
echo ""

echo "Firewall:"
if [[ "$FIREWALL_ENABLED" == "y" ]]; then
    echo "  Status:           SSH allowed"
elif command -v firewall-cmd >/dev/null 2>&1; then
    echo "  Status:           Firewalld available (SSH not allowed)"
else
    echo "  Status:           Firewalld not installed"
fi

echo ""
echo "[i] Connect using: 'ssh <username>@<server-ip>'"
