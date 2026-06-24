#!/bin/bash

# Resets ~/.bashrc to the distribution default (/etc/skel/.bashrc).
# Backs up the current ~/.bashrc with a timestamp before overwriting.
# Idempotent / safe: only acts after explicit confirmation.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RED='\033[0;31m'
NC='\033[0m'

BASHRC="$HOME/.bashrc"
SKEL_BASHRC="/etc/skel/.bashrc"
TS="$(date +%Y%m%d_%H%M%S)"

if [[ ! -f "$SKEL_BASHRC" ]]; then
    echo "[!] $SKEL_BASHRC not found, cannot reset."
    exit 1
fi

echo ""
echo -e "${RED}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║        [!]  R E S E T   W A R N I N G  [!]        ║${NC}"
echo -e "${RED}╠═══════════════════════════════════════════════════╣${NC}"
echo -e "${RED}║                                                   ║${NC}"
echo -e "${RED}║  This will replace ~/.bashrc with the default:    ║${NC}"
echo -e "${RED}║  $SKEL_BASHRC                                ║${NC}" # SKEL_BASHRC="/etc/skel/.bashrc"
echo -e "${RED}║                                                   ║${NC}"
echo -e "${RED}║  All customizations (bash-qol, oh-my-bash,        ║${NC}"
echo -e "${RED}║  aliases, etc.) will be REMOVED from ~/.bashrc.   ║${NC}"
echo -e "${RED}║                                                   ║${NC}"
echo -e "${RED}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

read -rp "[?] Reset ~/.bashrc to the default? [y/N]: " CONFIRM
case "${CONFIRM,,}" in
    y|yes)
        if [[ -f "$BASHRC" ]]; then
            cp "$BASHRC" "${BASHRC}.bak.${TS}"
            echo "[i] ~/.bashrc backed up to ${BASHRC}.bak.${TS}"
        fi
        cp "$SKEL_BASHRC" "$BASHRC"
        echo "[+] ~/.bashrc reset to $SKEL_BASHRC."
        echo
        echo "[i] Apply changes now with: source ~/.bashrc"
        ;;
    n|no|"")
        echo "[i] Cancelled, ~/.bashrc left unchanged."
        ;;
    *)
        echo "[!] Invalid input -> skipping ..."
        ;;
esac
