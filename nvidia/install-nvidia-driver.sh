#!/bin/bash

# Installs an NVIDIA GPU driver, either from the distro repo (nvidia-driver-XXX)
# or from a legacy/manual .run installer.
# Workflow: blacklists nouveau, stops the display manager and switches to
# multi-user.target (X/Wayland must be fully down before driver install/build),
# installs the driver, then restores graphical.target and reboots if needed.
# Requirements: root, Debian/Ubuntu-based system (apt), or a downloaded .run
# installer for the manual mode.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo "[!] Please log in as root and run this script."
    exit 1
fi

usage() {
    echo "Usage:"
    echo "  $0 --detect                          # auto-detect recommended driver and install it"
    echo "  $0 --package <nvidia-driver-XXX>     # install a specific package from apt repo"
    echo "  $0 --run <path-to-NVIDIA-....run>    # install from legacy .run installer"
    echo ""
    echo "Examples:"
    echo "  $0 --detect"
    echo "  $0 --package nvidia-driver-535"
    echo "  $0 --run /root/NVIDIA-Linux-x86_64-390.157.run"
    exit 1
}

# Detect recommended driver package via ubuntu-drivers (Ubuntu) or nvidia-detect (Debian).
# Prints the package name on stdout, exits non-zero if nothing could be detected.
detect_driver_package() {
    echo "[*] Looking for a GPU detection tool..." >&2

    if command -v ubuntu-drivers &>/dev/null; then
        echo "[i] Using ubuntu-drivers (Ubuntu)" >&2
        echo "" >&2
        ubuntu-drivers devices >&2 || true
        echo "" >&2
        local rec
        rec="$(ubuntu-drivers devices 2>/dev/null | awk '/recommended/ {print $3}' | head -n1)"
        if [[ -n "$rec" ]]; then
            echo "$rec"
            return 0
        fi
        echo "[!] ubuntu-drivers found no 'recommended' entry." >&2
        return 1
    fi

    if command -v nvidia-detect &>/dev/null; then
        echo "[i] Using nvidia-detect (Debian)" >&2
        echo "" >&2
        local out
        out="$(nvidia-detect 2>/dev/null)"
        echo "$out" >&2
        echo "" >&2
        local pkg
        pkg="$(echo "$out" | grep -oE 'nvidia-driver[a-zA-Z0-9_-]*' | tail -n1)"
        if [[ -n "$pkg" ]]; then
            echo "$pkg"
            return 0
        fi
        echo "[!] nvidia-detect did not return a package name." >&2
        return 1
    fi

    echo "[i] No detection tool found, installing ubuntu-drivers-common..." >&2
    if apt-get install -y ubuntu-drivers-common &>/dev/null && command -v ubuntu-drivers &>/dev/null; then
        echo "[+] ubuntu-drivers-common installed" >&2
        ubuntu-drivers devices >&2 || true
        echo "" >&2
        local rec2
        rec2="$(ubuntu-drivers devices 2>/dev/null | awk '/recommended/ {print $3}' | head -n1)"
        if [[ -n "$rec2" ]]; then
            echo "$rec2"
            return 0
        fi
    fi

    echo "[!] Could not auto-install or run a detection tool." >&2
    echo "[i] Install one manually:" >&2
    echo "      Ubuntu: apt-get install ubuntu-drivers-common" >&2
    echo "      Debian: apt-get install nvidia-detect" >&2
    return 1
}

MODE=""
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --detect)
            MODE="detect"
            shift
            ;;
        --package)
            MODE="package"
            TARGET="${2:-}"
            shift 2
            ;;
        --run)
            MODE="run"
            TARGET="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "[!] Unknown argument: $1"
            usage
            ;;
    esac
done

if [[ -z "$MODE" ]]; then
    usage
fi
if [[ "$MODE" != "detect" && -z "$TARGET" ]]; then
    usage
fi

# --detect resolves to a concrete package and then behaves like --package.
if [[ "$MODE" == "detect" ]]; then
    echo "-------------------Detecting GPU driver-------------------"
    if ! TARGET="$(detect_driver_package)"; then
        echo "[!] Auto-detection failed. Re-run with --package <name> or --run <file> instead."
        exit 1
    fi
    echo "[+] Detected recommended package: $TARGET"
    MODE="package"
fi

if [[ "$MODE" == "run" && ! -f "$TARGET" ]]; then
    echo "[!] .run installer not found: $TARGET"
    exit 1
fi

echo "-----------------Detecting environment-----------------"

CURRENT_TARGET="$(systemctl get-default 2>/dev/null || echo unknown)"
DM_SERVICE=""
for svc in gdm gdm3 sddm lightdm lxdm xdm; do
    if systemctl list-unit-files 2>/dev/null | grep -q "^${svc}.service"; then
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            DM_SERVICE="$svc"
            break
        fi
    fi
done

echo "[i] Default systemd target: $CURRENT_TARGET"
if [[ -n "$DM_SERVICE" ]]; then
    echo "[i] Active display manager: $DM_SERVICE"
else
    echo "[i] No active display manager detected (already in text mode?)"
fi

echo -e "${YELLOW}[!] This will stop the display manager and switch to multi-user.target.${NC}"
echo -e "${YELLOW}[!] If you're connected via GUI, your session will end.${NC}"
echo -e "${YELLOW}[!] Run this from SSH or a TTY, not from inside the graphical session.${NC}"
echo ""
read -rp "[?] Continue? [y/N]: " PROCEED
[[ "${PROCEED,,}" =~ ^y ]] || { echo "[i] Aborted."; exit 0; }

echo "-------------------Blacklisting nouveau-------------------"

NOUVEAU_CONF="/etc/modprobe.d/blacklist-nouveau.conf"
if [[ ! -f "$NOUVEAU_CONF" ]]; then
    cat > "$NOUVEAU_CONF" <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
    echo "[+] Wrote $NOUVEAU_CONF"
else
    echo "[i] $NOUVEAU_CONF already present, skipping"
fi

echo "[*] Updating initramfs..."
update-initramfs -u
echo "[+] initramfs updated"

echo "----------------Stopping graphical session----------------"

echo "[*] Switching to multi-user.target..."
systemctl isolate multi-user.target
echo "[+] Graphical target stopped, now on multi-user.target"

if [[ -n "$DM_SERVICE" ]]; then
    echo "[*] Disabling $DM_SERVICE from auto-starting on next boot..."
    systemctl stop "$DM_SERVICE" 2>/dev/null || true
fi

# Confirm nothing is holding the GPU
if command -v fuser &>/dev/null; then
    if fuser -v /dev/nvidia* 2>/dev/null; then
        echo -e "${RED}[!] Some process is still holding an /dev/nvidia* device.${NC}"
        echo -e "${RED}[!] Kill it manually before proceeding, or the install may fail.${NC}"
    fi
fi

if [[ "$MODE" == "package" ]]; then
    echo "-------------------Installing via apt-------------------"
    apt-get update
    echo "[*] Installing $TARGET ..."
    apt-get install -y "$TARGET"
    echo "[+] Package $TARGET installed"
else
    echo "----------------Installing via .run file----------------"
    chmod +x "$TARGET"
    echo "[*] Running $TARGET (silent, dkms, no X check)..."
    # --no-x-check: we already confirmed X is down manually above
    # --dkms: rebuild the module automatically on kernel updates
    "$TARGET" --silent --dkms --no-x-check
    echo "[+] .run installer finished"
fi

echo "-------------------Setup Complete!-------------------"
echo ""
echo "Driver installed via: $MODE ($TARGET)"
echo "Nouveau blacklist:    $NOUVEAU_CONF"
echo ""
echo "[i] A reboot is strongly recommended to fully load the new kernel module."
read -rp "[?] Reboot now? [y/N]: " DO_REBOOT
if [[ "${DO_REBOOT,,}" =~ ^y ]]; then
    echo "[*] Rebooting..."
    reboot
else
    echo "[i] Skipping reboot. To return to the graphical session manually, run:"
    echo "      'systemctl isolate graphical.target'"
    echo "[i] Or just reboot later with: 'reboot'"
fi
