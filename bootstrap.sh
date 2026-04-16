#!/bin/bash

# Server bootstrap for Debian/Ubuntu systems.
# Installs base admin tools, optional hardware diagnostics,
# and can configure sudo access, firewalld, and Fail2Ban.
# Recommended for Debian 12/13 and Ubuntu 22.04/24.04 LTS.

set -euo pipefail

# System PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

BASE_TOOLS="htop ranger nano curl wget git openssh-server ca-certificates gnupg bash-completion sudo"
HARDWARE_TOOLS="lm-sensors smartmontools ethtool pciutils usbutils inxi dmidecode hwinfo lshw parted nvme-cli sysstat iotop tcpdump bridge-utils"

echo "[*] Updating package lists..."
apt-get update

echo "[*] Upgrading installed packages..."
apt-get upgrade -y

echo "-------------------Profile setup------------------"
echo " Select Installation Profile:"
echo " 1) Base tools only"
echo " 2) Base + Hardware tools"
echo " 0) Cancel and exit."
echo "--------------------------------------------------"

read -rp "[>] Choice: " PROFILE_CHOICE

case "${PROFILE_CHOICE,,}" in
    1)
        echo "[*] Installing Base tools..."
        apt-get install -y $BASE_TOOLS
        ;;
    2)
        echo "[*] Installing Base + Hardware tools..."
        apt-get install -y $BASE_TOOLS $HARDWARE_TOOLS
        ;;
    0)
        echo "[i] Exit selected"
        exit 0
        ;;
    *)
        echo "[!] Invalid selection -> exiting"
        exit 1
        ;;
esac

echo "---------------Sudo group management--------------"

mapfile -t REGULAR_USERS < <(getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print $1}')

SELECTED_USER=""

if [[ ${#REGULAR_USERS[@]} -eq 0 ]]; then
    echo "[!] No regular users found."

    read -rp "[?] Create a new user? (y/N): " CREATE_NEW

    if [[ "${CREATE_NEW,,}" =~ ^[yY]$ ]]; then
        read -rp "[>] Enter username: " NEW_USER

        if [[ -z "$NEW_USER" ]]; then
            echo "[!] Username cannot be empty."
            exit 1
        fi

        adduser --disabled-password --gecos "" "$NEW_USER"
        SELECTED_USER="$NEW_USER"
    else
        echo "[i] Skipping user management."
        SELECTED_USER=""
    fi
else
    echo "[i] Current regular users:"

    for i in "${!REGULAR_USERS[@]}"; do
        echo "$((i+1))) ${REGULAR_USERS[i]}"
    done

    read -rp "[>] Select user number to add to sudo group (or 0 to skip): " IDX

    if [[ "$IDX" == "0" ]]; then
        echo "[i] Skipping user selection."
        SELECTED_USER=""
    elif [[ "$IDX" =~ ^[0-9]+$ ]] && (( IDX >= 1 && IDX <= ${#REGULAR_USERS[@]} )); then
        SELECTED_USER="${REGULAR_USERS[$((IDX-1))]}"
    else
        echo "[!] Invalid selection."
        exit 1
    fi
fi

# safe sudo assignment
if [[ -n "${SELECTED_USER}" ]] && id "$SELECTED_USER" &>/dev/null; then

    if getent group sudo >/dev/null; then
        SUDO_GROUP="sudo"
    else
        SUDO_GROUP="wheel"
    fi

    usermod -aG "$SUDO_GROUP" "$SELECTED_USER"
    echo "[+] User '$SELECTED_USER' added to $SUDO_GROUP group."
else
    echo "[i] No valid user selected, skipping sudo assignment."
fi

echo "------------------Firewall setup------------------"

read -rp "[?] Install Firewalld? [y/N]: " FIREWALL_CHOICE

case "${FIREWALL_CHOICE,,}" in
    y|yes)
        echo "[+] Installing and configuring firewalld..."

        if apt-get install -y firewalld; then
            systemctl enable --now firewalld

            firewall-cmd --permanent --zone=public --add-service=ssh
            firewall-cmd --reload
            firewall-cmd --set-default-zone=public

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

echo "------------------Fail2Ban setup------------------"

read -rp "[?] Install and configure Fail2Ban? [y/N]: " FAIL2BAN_CHOICE

case "${FAIL2BAN_CHOICE,,}" in
    y|yes)
        echo "[+] Installing Fail2Ban..."

        if apt-get install -y fail2ban; then

            cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
EOF

            echo "[+] Created /etc/fail2ban/jail.local"

            systemctl enable --now fail2ban

            echo "[i] Fail2Ban status:"
            if systemctl is-active --quiet fail2ban; then
                fail2ban-client status
            else
                echo "[!] Fail2Ban is not running"
            fi
        else
            echo "[!] Fail2Ban installation failed"
        fi
        ;;
    n|no|"")
        echo "[i] Fail2Ban setup skipped (default NO)"
        ;;
    *)
        echo "[!] Invalid input -> skipping Fail2Ban setup"
        ;;
esac

echo "------------------SYSTEM SUMMARY------------------"
echo ""

echo "Installed Profile:"
echo "Base tools: $BASE_TOOLS"
echo "Hardware tools: $HARDWARE_TOOLS"
echo ""

echo "Installed Packages:"
dpkg -l | awk '/htop|ranger|nano|curl|wget|git|openssh-server|ca-certificates|gnupg|bash-completion|sudo|lm-sensors|smartmontools|ethtool|pciutils|usbutils|inxi|dmidecode|hwinfo|lshw|parted|nvme-cli|sysstat|iotop|tcpdump|bridge-utils/ {print $2 " " $3}'
echo ""

echo "Users:"
getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 {print "- " $1 " (UID " $3 ")"}'
echo ""

echo "Sudo Group Members:"
getent group sudo 2>/dev/null || getent group wheel 2>/dev/null
echo ""

echo "SSH Service:"
systemctl is-active ssh || systemctl is-active sshd || echo "[!] SSH service not detected"
ss -tlnp | grep sshd || echo "[!] SSH port not detected"
echo ""

echo "Firewall:"
if systemctl is-active --quiet firewalld; then
    echo "[+] firewalld is ACTIVE"
    firewall-cmd --state
    echo ""
    echo "Default zone:"
    firewall-cmd --get-default-zone
    echo ""
    echo "Active zones:"
    firewall-cmd --get-active-zones
    echo ""
    echo "Public zone services:"
    firewall-cmd --zone=public --list-services
    echo ""
    echo "Open ports:"
    firewall-cmd --zone=public --list-ports
else
    echo "[-] firewalld NOT installed or inactive"
fi
echo ""

echo "Fail2Ban:"
if systemctl is-active --quiet fail2ban; then
    echo "[+] Fail2Ban is ACTIVE"
    fail2ban-client status 2>/dev/null || echo "[!] fail2ban-client unavailable"
else
    echo "[-] Fail2Ban not active"
fi
echo ""

echo "Network Summary:"
ip a | grep -E "inet " | awk '{print $2 " " $NF}'
echo ""

echo "System Info:"
uname -a
echo ""
uptime
echo ""

echo "Disk Summary:"
lsblk
echo ""

echo "--------------------------------------------------"
echo "[✓] System setup completed"
