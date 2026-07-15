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

# Distro ID, used to pick a detection tool and know which non-free component
# to check for (Debian: non-free-firmware/non-free, Ubuntu: restricted).
DISTRO_ID="unknown"
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO_ID="${ID:-unknown}"
fi

# Detect recommended driver package via ubuntu-drivers (Ubuntu) or nvidia-detect (Debian).
# Prints the package name on stdout, exits non-zero if nothing could be detected.
detect_driver_package() {
    echo "[*] Looking for a GPU detection tool..." >&2

    if [[ "$DISTRO_ID" == "ubuntu" ]] && command -v ubuntu-drivers &>/dev/null; then
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

    if [[ "$DISTRO_ID" == "debian" ]] && command -v nvidia-detect &>/dev/null; then
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

    case "$DISTRO_ID" in
        ubuntu)
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
            ;;
        debian)
            echo "[i] No detection tool found, installing nvidia-detect..." >&2
            apt-get update &>/dev/null || true
            if apt-get install -y nvidia-detect &>/dev/null && command -v nvidia-detect &>/dev/null; then
                echo "[+] nvidia-detect installed" >&2
                local out2
                out2="$(nvidia-detect 2>/dev/null)"
                echo "$out2" >&2
                echo "" >&2
                local pkg2
                pkg2="$(echo "$out2" | grep -oE 'nvidia-driver[a-zA-Z0-9_-]*' | tail -n1)"
                if [[ -n "$pkg2" ]]; then
                    echo "$pkg2"
                    return 0
                fi
            fi
            ;;
        *)
            echo "[!] Unrecognized distribution ID: '$DISTRO_ID' — skipping auto-install of a detector." >&2
            ;;
    esac

    echo "[!] Could not auto-install or run a detection tool." >&2
    echo "[i] Install one manually:" >&2
    echo "      Ubuntu: 'apt-get install ubuntu-drivers-common'" >&2
    echo "      Debian: 'apt-get install nvidia-detect'" >&2
    return 1
}

# Confirms the repo component that ships proprietary NVIDIA packages is enabled
# (Ubuntu: restricted, Debian: non-free-firmware or the older non-free) so a
# plain `apt-get install nvidia-driver-XXX` doesn't fail with "Unable to locate package".
check_nonfree_component_enabled() {
    local sources_glob=(/etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources)
    local found=0
    case "$DISTRO_ID" in
        ubuntu)
            grep -h -E '^[^#].*restricted' "${sources_glob[@]}" &>/dev/null && found=1
            ;;
        debian)
            grep -h -E '^[^#].*(non-free-firmware|non-free)' "${sources_glob[@]}" &>/dev/null && found=1
            ;;
        *)
            return 0
            ;;
    esac

    if [[ "$found" -eq 0 ]]; then
        echo "[!] Could not confirm the non-free/restricted component is enabled in APT sources."
        echo "[!] 'apt-get install' may fail with 'Unable to locate package' until it's added."
    else
        echo "[i] Non-free/restricted component appears enabled."
    fi
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

echo "-------------------------------------------------"
echo "[i] Distribution: ${PRETTY_NAME:-$DISTRO_ID}"

# Already-installed check — avoid pointless reinstalls/reboots.
if lsmod | grep -q '^nvidia' && command -v nvidia-smi &>/dev/null; then
    echo "[i] An NVIDIA driver already appears to be loaded:"
    nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | sed 's/^/[i]   Driver version: /' || true
    read -rp "[?] Continue anyway and (re)install? [y/N]: " REINSTALL
    [[ "${REINSTALL,,}" =~ ^y ]] || { echo "[i] Aborted, nothing changed."; exit 0; }
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

if [[ "$MODE" == "package" ]]; then
    check_nonfree_component_enabled
fi

echo "-----------------Detecting environment-----------------"

CURRENT_TARGET="$(systemctl get-default 2>/dev/null || echo unknown)"
DM_SERVICE="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" .service 2>/dev/null || true)"
if [[ -n "$DM_SERVICE" ]] && ! systemctl is-active --quiet "$DM_SERVICE" 2>/dev/null; then
    DM_SERVICE=""
fi

echo "[i] Default systemd target: $CURRENT_TARGET"
if [[ -n "$DM_SERVICE" ]]; then
    echo "[i] Active display manager: $DM_SERVICE"
else
    echo "[i] No active display manager detected (already in text mode?)"
fi

# DKMS + kernel headers are required for both the .run --dkms path and most
# apt nvidia-driver-XXX packages (which build the module via dkms as well).
echo "[*] Checking for dkms and kernel headers..."
MISSING_DEPS=()
command -v dkms &>/dev/null || MISSING_DEPS+=("dkms")
dpkg -s "linux-headers-$(uname -r)" &>/dev/null || MISSING_DEPS+=("linux-headers-$(uname -r)")
if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    echo "[i] Installing missing build dependencies: ${MISSING_DEPS[*]}"
    apt-get update
    apt-get install -y "${MISSING_DEPS[@]}"
    echo "[+] Build dependencies installed"
else
    echo "[i] dkms and matching kernel headers already present."
fi

# Secure Boot check — an unsigned/self-signed dkms module can install cleanly
# but still fail to load at boot under Secure Boot (nvidia-smi: "No devices were found").
if command -v mokutil &>/dev/null && mokutil --sb-state 2>/dev/null | grep -qi "enabled"; then
    echo -e "${YELLOW}[!] Secure Boot is enabled.${NC}"
    echo -e "${YELLOW}[!] The NVIDIA kernel module must be signed (e.g. via dkms/mokutil MOK enrollment)${NC}"
    echo -e "${YELLOW}[!] or it will fail to load after reboot even though installation succeeds.${NC}"
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
    echo "[i] $NOUVEAU_CONF already present, skipping..."
fi

echo "[*] Updating initramfs..."
update-initramfs -u
echo "[+] initramfs updated."

echo "----------------Stopping graphical session----------------"

echo "[*] Switching to multi-user.target..."
systemctl isolate multi-user.target
echo "[+] Graphical target stopped, now on multi-user.target"

# Confirm the display server actually exited — isolate can return before
# every session/process has fully torn down.
for proc in Xorg Xwayland X; do
    if pgrep -x "$proc" &>/dev/null; then
        echo -e "${YELLOW}[!] '$proc' is still running after isolate; waiting a moment...${NC}"
        sleep 2
        pgrep -x "$proc" &>/dev/null && echo -e "${RED}[!] '$proc' is still running. It may need to be killed manually.${NC}"
    fi
done

# Confirm nothing is holding the GPU. /dev/nvidia* may not exist yet on a
# fresh install, so check the DRI nodes too, which are always present.
if command -v fuser &>/dev/null; then
    if fuser -v /dev/nvidia* /dev/dri/* 2>/dev/null; then
        echo -e "${RED}[!] Some process is still holding an NVIDIA/DRI device.${NC}"
        echo -e "${RED}[!] Kill it manually before proceeding, or the install may fail.${NC}"
    fi
fi

if [[ "$MODE" == "package" ]]; then
    echo "-------------------Installing via apt-------------------"
    apt-get update
    echo "[*] Installing $TARGET ..."
    apt-get install -y "$TARGET"
    echo "[+] Package $TARGET installed."
else
    echo "----------------Installing via .run file----------------"
    chmod +x "$TARGET"
    echo "[*] Running $TARGET (silent, dkms, no X check, no UI)..."
    # --no-x-check: we already confirmed X is down manually above
    # --dkms: rebuild the module automatically on kernel updates
    # --ui=none: guarantees the installer never tries an ncurses/GUI prompt
    "$TARGET" --silent --dkms --no-x-check --ui=none
    echo "[+] .run installer finished"
fi

echo "[*] Refreshing initramfs after driver install..."
update-initramfs -u
echo "[+] initramfs refreshed."

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
    echo "[i] After reboot, verify with: 'nvidia-smi' and 'lsmod | grep nvidia'"
fi
