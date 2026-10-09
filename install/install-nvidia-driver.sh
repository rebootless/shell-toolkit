#!/bin/bash

# ---DOC-START---
# summary: NVIDIA GPU driver installer (auto-detect, apt package, or .run).
# description: |
#   Installs an NVIDIA GPU driver, either from the distro's apt repository or from a legacy/manual `.run` installer.
#
#   - Usage: `sudo ./install-nvidia-driver.sh --detect` (auto-detects the recommended package via `ubuntu-drivers` or `nvidia-detect`), `--package <nvidia-driver-XXX>`, or `--run <path-to-.run>`
#   - Blacklists the `nouveau` driver before installing
#   - **Must be run from a text TTY** (not from X11/Wayland)
#   - Refuses to continue if a graphical session is detected
#   - Warns if a process is still holding `/dev/nvidia*` before proceeding
#   - Installs via `apt-get install` (package mode) or runs the `.run` file with `--silent --dkms --no-x-check` (manual mode)
# sudo: true
# interactive: true
# idempotent: mostly
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo "Please log in as root and run this script."
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
    echo "Looking for a GPU detection tool..." >&2

    if [[ "$DISTRO_ID" == "ubuntu" ]] && command -v ubuntu-drivers &>/dev/null; then
        echo "Using ubuntu-drivers (Ubuntu)" >&2
        echo "" >&2
        ubuntu-drivers devices >&2 || true
        echo "" >&2
        local rec
        rec="$(ubuntu-drivers devices 2>/dev/null | awk '/recommended/ {print $3}' | head -n1)"
        if [[ -n "$rec" ]]; then
            echo "$rec"
            return 0
        fi
        echo "ubuntu-drivers found no 'recommended' entry." >&2
        return 1
    fi

    if [[ "$DISTRO_ID" == "debian" ]] && command -v nvidia-detect &>/dev/null; then
        echo "Using nvidia-detect (Debian)" >&2
        echo "" >&2
        local out
        out="$(nvidia-detect 2>/dev/null)"
        echo "$out" >&2
        echo "" >&2
        local pkg
        pkg="$(echo "$out" | awk '/It is recommended to install the/ {getline; print $1; exit}')"
        if [[ -n "$pkg" ]]; then
            echo "$pkg"
            return 0
        fi
        echo "nvidia-detect did not return a package name." >&2
        return 1
    fi

    case "$DISTRO_ID" in
        ubuntu)
            echo "No detection tool found, installing ubuntu-drivers-common..." >&2
            if apt-get install -y ubuntu-drivers-common &>/dev/null && command -v ubuntu-drivers &>/dev/null; then
                echo "ubuntu-drivers-common installed" >&2
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
            echo "No detection tool found, installing nvidia-detect..." >&2
            apt-get update &>/dev/null || true
            if apt-get install -y nvidia-detect &>/dev/null && command -v nvidia-detect &>/dev/null; then
                echo "nvidia-detect installed" >&2
                local out2
                out2="$(nvidia-detect 2>/dev/null)"
                echo "$out2" >&2
                echo "" >&2
                local pkg2
                pkg2="$(echo "$out2" | awk '/It is recommended to install the/ {getline; print $1; exit}')"
                if [[ -n "$pkg2" ]]; then
                    echo "$pkg2"
                    return 0
                fi
            fi
            ;;
        *)
            echo "Unrecognized distribution ID: '$DISTRO_ID' — skipping auto-install of a detector." >&2
            ;;
    esac

    echo "Could not auto-install or run a detection tool." >&2
    echo "Install one manually:" >&2
    echo "Ubuntu:" >&2
    echo "apt-get install ubuntu-drivers-common" >&2
    echo "Debian:" >&2
    echo "apt-get install nvidia-detect" >&2
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
            echo "Unknown argument: $1"
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

echo "Distribution: ${PRETTY_NAME:-$DISTRO_ID}"

# Already-installed check — avoid pointless reinstalls/reboots.
if lsmod | grep -q '^nvidia' && command -v nvidia-smi &>/dev/null; then
    echo "An NVIDIA driver already appears to be loaded:"
    nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | sed 's/^/ Driver version: /' || true
    read -rp "Continue anyway and (re)install? [y/N]: " REINSTALL
    [[ "${REINSTALL,,}" =~ ^y ]] || { echo "Aborted, nothing changed."; exit 0; }
fi

# --detect resolves to a concrete package and then behaves like --package.
if [[ "$MODE" == "detect" ]]; then
    echo "==> Detecting GPU driver"
    if ! TARGET="$(detect_driver_package)"; then
        echo "Auto-detection failed. Re-run with --package <name> or --run <file> instead."
        exit 1
    fi
    echo "Detected recommended package: $TARGET"
    MODE="package"
fi

if [[ "$MODE" == "package" ]] && dpkg -s "$TARGET" &>/dev/null; then
    echo "Package already installed: $TARGET"

    read -rp "Reinstall anyway? [y/N]: " REINSTALL
    [[ "${REINSTALL,,}" =~ ^y ]] || exit 0
fi

if [[ "$MODE" == "run" ]]; then
    if [[ ! -e "$TARGET" ]]; then
        echo ".run installer not found: $TARGET"
        exit 1
    fi

    if [[ ! -f "$TARGET" ]]; then
        echo "Not a regular file: $TARGET"
        exit 1
    fi

    if [[ ! -r "$TARGET" ]]; then
        echo "Installer is not readable: $TARGET"
        exit 1
    fi
fi

echo "==> Detecting environment"

echo "Checking for a graphical session..."

if pgrep -x Xorg >/dev/null \
    || pgrep -x Xwayland >/dev/null \
    || pgrep -x X >/dev/null; then

    echo -e "${RED}A graphical session is currently running.${NC}"
    echo ""
    echo "This installer must be run with the graphical session stopped."
    echo ""
    echo "If you are currently in the graphical desktop:"
    echo "  1. Switch to a text console (Ctrl+Alt+F2...F6)"
    echo "  2. Log in"
    echo "  3. Run:"
    echo "    sudo systemctl isolate multi-user.target"
    echo ""
    echo "If you are already in a text console, simply run:"
    echo "  sudo systemctl isolate multi-user.target"
    echo ""
    echo "Then re-run this script."
    echo ""
    echo "To restore the graphical session later:"
    echo "  sudo systemctl isolate graphical.target"
    exit 1
fi

echo "No graphical session detected."

CURRENT_TARGET="$(systemctl get-default 2>/dev/null || echo unknown)"
DM_SERVICE="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" .service 2>/dev/null || true)"
if [[ -n "$DM_SERVICE" ]] && ! systemctl is-active --quiet "$DM_SERVICE" 2>/dev/null; then
    DM_SERVICE=""
fi

echo "Default systemd target: $CURRENT_TARGET"
if [[ -n "$DM_SERVICE" ]]; then
    echo "Active display manager: $DM_SERVICE"
else
    echo "No active display manager detected (already in text mode?)"
fi

# DKMS + kernel headers are required for both the .run --dkms path and most
# apt nvidia-driver-XXX packages (which build the module via dkms as well).
echo "Checking for dkms and kernel headers..."
MISSING_DEPS=()
command -v dkms &>/dev/null || MISSING_DEPS+=("dkms")
dpkg -s "linux-headers-$(uname -r)" &>/dev/null || MISSING_DEPS+=("linux-headers-$(uname -r)")
if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    echo "Installing missing build dependencies: ${MISSING_DEPS[*]}"
    apt-get update
    apt-get install -y "${MISSING_DEPS[@]}"
    echo "Build dependencies installed"
else
    echo "dkms and matching kernel headers already present."
fi

# Secure Boot check — an unsigned/self-signed dkms module can install cleanly
# but still fail to load at boot under Secure Boot (nvidia-smi: "No devices were found").
if command -v mokutil &>/dev/null && mokutil --sb-state 2>/dev/null | grep -qi "enabled"; then
    echo -e "${YELLOW}Secure Boot is enabled.${NC}"
    echo -e "${YELLOW}The NVIDIA kernel module must be signed (e.g. via dkms/mokutil MOK enrollment)${NC}"
    echo -e "${YELLOW}or it will fail to load after reboot even though installation succeeds.${NC}"
fi

# Confirm nothing is holding the GPU. /dev/nvidia* may not exist yet on a
# fresh install, so check the DRI nodes too, which are always present.
if command -v fuser &>/dev/null; then
    if fuser -v /dev/nvidia* /dev/dri/* 2>/dev/null; then
        echo -e "${RED}Some process is still holding an NVIDIA/DRI device.${NC}"
        echo ""
        echo "Stop the graphical session:"
        echo "  sudo systemctl isolate multi-user.target"
        echo ""
        echo "Then re-run this script."
exit 1
    fi
fi

NOUVEAU_CONF="/etc/modprobe.d/nvidia-installer-disable-nouveau.conf"

touch "$NOUVEAU_CONF"

grep -qxF 'blacklist nouveau' "$NOUVEAU_CONF" \
    || echo 'blacklist nouveau' >>"$NOUVEAU_CONF"

grep -qxF 'options nouveau modeset=0' "$NOUVEAU_CONF" \
    || echo 'options nouveau modeset=0' >>"$NOUVEAU_CONF"

echo "Updated $NOUVEAU_CONF"

echo "Refreshing initramfs after blacklisting nouveau..."
update-initramfs -u
echo "initramfs refreshed."

if [[ "$MODE" == "package" ]]; then
    echo "==> Installing via apt"
    apt-get update
    echo "Installing $TARGET ..."
    apt-get install -y "$TARGET"
    echo "Package $TARGET installed."
else
    echo "==> Installing via .run file"
    chmod +x "$TARGET"
    echo "Running $TARGET (silent, dkms, no X check, no UI)..."
    # --no-x-check: we already confirmed X is down manually above
    # --dkms: rebuild the module automatically on kernel updates
    # --ui=none: guarantees the installer never tries an ncurses/GUI prompt
    "$TARGET" --silent --dkms --no-x-check --ui=none
    echo ".run installer finished"
fi

echo "Refreshing initramfs after driver install..."
update-initramfs -u
echo "initramfs refreshed."

echo ""
echo "==> Summary"

echo ""
echo "Installation method:  $MODE"
echo "Target:               $TARGET"

if [[ -f "$NOUVEAU_CONF" ]]; then
    echo "Nouveau blacklist:  $NOUVEAU_CONF"
fi

echo ""
echo "A reboot is required for the NVIDIA kernel module to replace nouveau."
read -rp "Reboot now? [y/N]: " DO_REBOOT
if [[ "${DO_REBOOT,,}" =~ ^y ]]; then
    echo "Rebooting..."
    reboot
else
    echo "Skipping reboot."
    echo "Reboot the system later to load the NVIDIA kernel module."
    echo ""
    echo "After reboot, verify with:"
    echo "  nvidia-smi"
    echo "  lsmod | grep nvidia"
fi
