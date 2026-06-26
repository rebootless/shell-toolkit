#!/bin/bash

# Gathers detailed server information (optimized for Debian/Ubuntu), saves
# all data into .txt files in ~/server-report, packs them into a .tar.gz
# archive, and prints a clean summary to the console.
#
# --- CORE UTILITIES (Usually pre-installed) ---
# systemctl, journalctl, ip, ss, free, ps, df, lsblk, lscpu, dpkg-query
#
# --- 3RD-PARTY SOFTWARE (Auto-detected) ---
# The script automatically checks for and logs data from:
# - Docker (containers, networks, volumes, info)
# - Nginx (version, config test)
# - Firewalls (UFW, Firewalld, iptables)
# - Cron & Tree (directory structures)

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "-------------Installing dependencies-------------"
echo "[*] Updating system packages..."
apt-get update -q

echo "[*] Installing dependencies..."
apt-get install -y pciutils usbutils dmidecode lshw tree

echo "----------------Server information---------------"

REPORT_DIR="$HOME/server-report"

mkdir -p "$REPORT_DIR"

echo "[+] Output directory: $REPORT_DIR"

echo "----------------System information---------------"
echo "[*] Collecting system info..."

hostnamectl > "$REPORT_DIR/hostnamectl.txt"
cat /etc/os-release > "$REPORT_DIR/os-release.txt"
uname -a > "$REPORT_DIR/uname.txt"
uptime > "$REPORT_DIR/uptime.txt"
sysctl -a > "$REPORT_DIR/sysctl.txt" 2>/dev/null || true
dmesg > "$REPORT_DIR/dmesg.txt"

echo "[+] System information collected."

echo "----------------Hardware resources---------------"
echo "[*] Collecting hardware info..."

lscpu > "$REPORT_DIR/lscpu.txt"
free -h > "$REPORT_DIR/memory.txt"
df -h > "$REPORT_DIR/storage.txt"
lsblk > "$REPORT_DIR/lsblk.txt"
lspci > "$REPORT_DIR/lspci.txt" 2>/dev/null || true
lsusb > "$REPORT_DIR/lsusb.txt" 2>/dev/null || true

if command -v dmidecode >/dev/null 2>&1; then
    dmidecode > "$REPORT_DIR/dmidecode.txt" 2>/dev/null || true
fi

if command -v lshw >/dev/null 2>&1; then
    lshw > "$REPORT_DIR/lshw.txt" 2>/dev/null || true
fi

echo "[+] Hardware information collected."

echo "----------------Network information--------------"
echo "[*] Collecting network info..."

ip -br a > "$REPORT_DIR/interfaces.txt"
ip route > "$REPORT_DIR/routes.txt"
ss -tulpn > "$REPORT_DIR/open-ports.txt"
cat /etc/resolv.conf > "$REPORT_DIR/resolv-conf.txt"
cat /etc/hosts > "$REPORT_DIR/hosts.txt"

if command -v iptables-save >/dev/null 2>&1; then
    iptables-save > "$REPORT_DIR/iptables-rules.txt"
fi

echo "[+] Network information collected."

echo "----------------Users and Processes--------------"
echo "[*] Collecting users and process info..."

ps aux > "$REPORT_DIR/processes.txt"
cat /etc/passwd > "$REPORT_DIR/passwd.txt"
cat /etc/group > "$REPORT_DIR/group.txt"
w > "$REPORT_DIR/logged-in-users.txt"
last -n 50 > "$REPORT_DIR/last-logins.txt"

if command -v crontab >/dev/null 2>&1; then
    crontab -l > "$REPORT_DIR/root-crontab.txt" 2>/dev/null || true
fi

echo "[+] Users and processes collected."

echo "----------------Packages and Logs----------------"
echo "[*] Collecting packages and logs..."

dpkg-query -l > "$REPORT_DIR/installed-packages.txt" 2>/dev/null || true
journalctl -p 3 -xb > "$REPORT_DIR/journal-errors.txt" 2>/dev/null || true

echo "[+] Packages and logs collected."

echo "----------------Firewall information-------------"

if command -v ufw >/dev/null 2>&1; then
    ufw status verbose > "$REPORT_DIR/ufw-status.txt"
    echo "[+] UFW information collected."
elif command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --get-active-zones > "$REPORT_DIR/firewalld-zones.txt"
    firewall-cmd --list-all > "$REPORT_DIR/firewalld.txt"
    echo "[+] Firewalld information collected."
else
    echo "[i] Firewall (UFW/Firewalld) not installed or active."
fi

echo "----------------Service information--------------"
echo "[*] Collecting service info..."

systemctl --type=service --state=running > "$REPORT_DIR/running-services.txt"
systemctl list-unit-files --state=enabled > "$REPORT_DIR/enabled-services.txt"

echo "[+] Service information collected."

echo "----------------Docker information---------------"

if command -v docker >/dev/null 2>&1; then
    docker ps -a > "$REPORT_DIR/docker-containers.txt"
    docker network ls > "$REPORT_DIR/docker-networks.txt"
    docker volume ls > "$REPORT_DIR/docker-volumes.txt"
    docker info > "$REPORT_DIR/docker-info.txt" 2>/dev/null || true
    echo "[+] Docker information collected."
else
    echo "[i] Docker not installed."
fi

echo "----------------Nginx information----------------"

if command -v nginx >/dev/null 2>&1; then
    nginx -v > "$REPORT_DIR/nginx-version.txt" 2>&1
    nginx -T > "$REPORT_DIR/nginx-config.txt" 2>&1
    echo "[+] Nginx information collected."
else
    echo "[i] Nginx not installed."
fi

echo "----------------Directory structure--------------"

if command -v tree >/dev/null 2>&1; then
    tree -L 2 /srv > "$REPORT_DIR/srv-tree.txt" 2>/dev/null || true
    tree -L 2 /opt > "$REPORT_DIR/opt-tree.txt" 2>/dev/null || true
    tree -L 2 /var/www > "$REPORT_DIR/var-www-tree.txt" 2>/dev/null || true
    echo "[+] Directory structure collected."
else
    echo "[i] Tree command not installed."
fi

echo "-----------------Archive creation----------------"

tar -czf server-report.tar.gz "$REPORT_DIR"

echo "[+] Archive created: server-report.tar.gz"

echo "-----------------Setup Complete!-----------------"

SYS_OS=$(grep -w "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"' || echo "Unknown")
SYS_KERN=$(uname -r || echo "Unknown")
SYS_HOST=$(hostname || echo "Unknown")
SYS_UP=$(uptime -p || echo "Unknown")
SYS_LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}' || echo "Unknown")

SYS_CPU=$(lscpu | grep "Model name" | sed -r 's/Model name:\s+//g' || echo "Unknown")
SYS_CORES=$(nproc || echo "Unknown")

SYS_MEM_T=$(free -m | awk '/^Mem:/ {print $2"MB"}' || echo "Unknown")
SYS_MEM_U=$(free -m | awk '/^Mem:/ {print $3"MB"}' || echo "Unknown")
SYS_SWAP_T=$(free -m | awk '/^Swap:/ {print $2"MB"}' || echo "0MB")
SYS_SWAP_U=$(free -m | awk '/^Swap:/ {print $3"MB"}' || echo "0MB")

SYS_DISK_T=$(df -h / | awk 'NR==2 {print $2}' || echo "Unknown")
SYS_DISK_U=$(df -h / | awk 'NR==2 {print $3}' || echo "Unknown")

SYS_IPS=$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | paste -sd "," - || echo "None")
SYS_PORTS=$(ss -tulpn | tail -n +2 | wc -l || echo "0")
SYS_PKGS=$(dpkg-query -f '${binary:Package}\n' -W 2>/dev/null | wc -l || echo "Unknown")

SYS_SVC=$(systemctl --type=service --state=running --no-pager | grep running | wc -l || echo "0")
SYS_DOCKER_RUN=$(command -v docker >/dev/null 2>&1 && docker ps -q | wc -l || echo "N/A")

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    S E R V E R   S U M M A R Y                   ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "OS:" "$SYS_OS"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "Kernel:" "$SYS_KERN"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "Hostname:" "$SYS_HOST"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "Uptime:" "$SYS_UP"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "Load Avg:" "$SYS_LOAD"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "CPU Model:" "$SYS_CPU"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "CPU Cores:" "$SYS_CORES"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "RAM Usage:" "$SYS_MEM_U / $SYS_MEM_T"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "Swap Usage:" "$SYS_SWAP_U / $SYS_SWAP_T"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "Root Disk:" "$SYS_DISK_U used of $SYS_DISK_T"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "IP Addresses:" "$SYS_IPS"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "Listen Ports:" "$SYS_PORTS open"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "Packages:" "$SYS_PKGS installed (dpkg)"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "Services:" "$SYS_SVC running"
printf "${GREEN}║${NC} ${YELLOW}%-15s${NC} %-48s ${GREEN}║${NC}\n" "Docker Cont.:" "$SYS_DOCKER_RUN running"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Report directory: $REPORT_DIR"
echo "Archive file:     $(pwd)/server-report.tar.gz"
echo ""
