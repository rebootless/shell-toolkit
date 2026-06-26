#!/bin/bash

# Installs oh-my-bash and lets you pick a theme via an interactive
# preview (Tab = next theme, Enter = confirm), using chafa to render
# theme screenshots in the terminal.
#
# Two modes:
#   1) Official installer - runs the upstream install.sh, which REPLACES
#      ~/.bashrc with its own template (backup as ~/.bashrc.omb-*,
#      plus an extra ~/.bashrc.bak.TIMESTAMP from this script).
#   2) Manual integration - git-clones oh-my-bash to ~/.oh-my-bash and
#      prepends a small managed block (>>> oh-my-bash >>>) to the TOP of
#      ~/.bashrc, without touching any existing lines (e.g. bash-qol block
#      stays at the end, untouched).
#
# Idempotent: if oh-my-bash is already installed, only the theme picker
# (and, in manual mode, the managed block) is refreshed.
# Requirements: sudo access for package installation (chafa, git).

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RED='\033[0;31m'
NC='\033[0m'

BASHRC="$HOME/.bashrc"
OSH="$HOME/.oh-my-bash"
TS="$(date +%Y%m%d_%H%M%S)"
MARK_START="# >>> oh-my-bash >>>"
MARK_END="# <<< oh-my-bash <<<"

echo "---------------Installing packages---------------"
echo "[*] Updating package lists..."
sudo apt update -qq

echo "[*] Installing: chafa, git"
sudo apt install -y chafa git
echo "[+] Packages installed."

echo "-------------------Oh My Bash--------------------"

MODE=""
if [[ -d "$OSH" ]]; then
    echo "[INFO] oh-my-bash already installed at $OSH."
    echo "    Skipping installation, only refreshing the theme."
    # Detect how it's wired into ~/.bashrc so we know what to refresh
    if grep -qF "$MARK_START" "$BASHRC" 2>/dev/null; then
        MODE="manual"
    else
        MODE="official"
    fi
else
    echo "[INFO] Choose how to integrate oh-my-bash:"
    echo "    1) Official installer - REPLACES ~/.bashrc with its template"
    echo "       (backup as ~/.bashrc.omb-*, plus our own backup)."
    echo "    2) Manual integration - git clone + small block prepended to"
    echo "       the TOP of ~/.bashrc, nothing else is touched or removed."
    read -rp "[?] Select mode [1/2]: " MODE_CHOICE
    case "$MODE_CHOICE" in
        1) MODE="official" ;;
        2) MODE="manual" ;;
        *)
            echo "[!] Invalid choice, aborting."
            exit 1
            ;;
    esac
fi

case "$MODE" in
    official)
        if [[ ! -d "$OSH" ]]; then
            echo ""
            echo "[INFO] The official installer will REPLACE ~/.bashrc with its own template."
            echo "    Any existing config (bash-qol blocks, aliases, etc.) will be lost."
            echo "    The installer saves its own backup as ~/.bashrc.omb-TIMESTAMP."
            echo ""
            read -rp "[?] Proceed with the official installer? [y/N]: " CONFIRM
            case "${CONFIRM,,}" in
                y|yes)
                    read -rp "[?] Are you sure? This cannot be undone. Type 'yes' to confirm: " CONFIRM2
                    if [[ "$CONFIRM2" != "yes" ]]; then
                        echo "[i] Confirmation not received — aborting."
                        exit 0
                    fi
                    echo "[*] Installing oh-my-bash..."
                    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended
                    echo "[+] oh-my-bash installed."
                    ;;
                n|no|"")
                    echo "[i] Skipping oh-my-bash."
                    exit 0
                    ;;
                *)
                    echo "[!] Invalid input -> skipping ..."
                    exit 0
                    ;;
            esac
        fi
        ;;

    manual)
        if [[ ! -d "$OSH" ]]; then
            echo "[*] Cloning oh-my-bash into $OSH..."
            git clone https://github.com/ohmybash/oh-my-bash.git "$OSH"
            echo "[+] oh-my-bash cloned."
        fi
        ;;
esac

echo "-----------------Theme selection-----------------"

THEMES=()
while IFS= read -r -d '' f; do
    THEMES+=("$(basename "$(dirname "$f")")")
done < <(find "$OSH/themes" -maxdepth 2 -name '*.theme.sh' -print0 | sort -z)

if [[ ${#THEMES[@]} -eq 0 ]]; then
    echo "[!] No themes found, skipping theme selection."
    exit 0
fi

idx=0
while true; do
    theme="${THEMES[$idx]}"
    theme_dir="$OSH/themes/$theme"

    img_file=$(find "$theme_dir" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -n 1)

    clear
    echo "[Tab] = next theme, [Enter] = confirm selection"
    echo "-------------------------------------------------"
    echo "[$((idx+1))/${#THEMES[@]}] Theme: $theme"
    echo ""
    echo "Preview:"

    if [[ -n "$img_file" && -f "$img_file" ]]; then
        chafa --size=65x16 "$img_file"
    else
        echo "[No preview image available for this theme]"
    fi
    echo ""

    IFS= read -rsn1 key
    if [[ "$key" == $'\t' ]]; then
        idx=$(((idx + 1) % ${#THEMES[@]}))
    elif [[ -z "$key" ]]; then
        clear
        break
    fi
done
OMB_THEME="${THEMES[$idx]}"

case "$MODE" in
    official)
        if grep -qE "^(export[[:space:]]+)?OSH_THEME=" "$BASHRC"; then
            sed -i -E "s/^(export[[:space:]]+)?OSH_THEME=.*/\1OSH_THEME=\"${OMB_THEME}\"/" "$BASHRC"
        else
            sed -i "1i export OSH_THEME=\"${OMB_THEME}\"" "$BASHRC"
        fi
        ;;

    manual)
        if [[ -f "$BASHRC" ]]; then
            cp "$BASHRC" "${BASHRC}.bak.${TS}"
            echo "[i] ~/.bashrc backed up to ${BASHRC}.bak.${TS}"
            if grep -qF "$MARK_START" "$BASHRC"; then
                sed -i "/${MARK_START}/,/${MARK_END}/d" "$BASHRC"
                echo "[i] Removed previous oh-my-bash block."
            fi
        else
            touch "$BASHRC"
            echo "[i] No existing ~/.bashrc found, creating new one."
        fi

        # Prepend block to TOP of ~/.bashrc; every existing line stays untouched
        {
            echo "$MARK_START"
            echo "export OSH=\"$OSH\""
            echo "OSH_THEME=\"$OMB_THEME\""
            echo "source \"\$OSH/oh-my-bash.sh\""
            echo "$MARK_END"
            echo ""
            cat "$BASHRC"
        } > "${BASHRC}.tmp"
        mv "${BASHRC}.tmp" "$BASHRC"
        echo "[i] oh-my-bash block prepended to the top of ~/.bashrc."
        ;;
esac

echo "[+] oh-my-bash theme set to: $OMB_THEME"

echo ""
echo "================================================="
echo "               Setup Complete!                   "
echo "================================================="
echo "[SUCCESS] oh-my-bash : $OSH"
echo "          Mode       : $MODE"
echo "          Theme      : $OMB_THEME"
if [[ "$MODE" == "official" ]]; then
    echo "          ~/.bashrc was REPLACED by the installer."
    echo "          Re-run bash-qol.sh to restore its managed block if needed."
else
    echo "          ~/.bashrc was only prepended; the bash-qol block is untouched."
fi
echo ""
echo "          Apply changes now with: source ~/.bashrc"
