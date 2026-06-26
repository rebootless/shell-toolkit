#!/bin/bash

# Downloads and installs Eclipse Temurin JDK/JRE builds into /opt/java/temurin/.
# Re-runnable: existing version dirs trigger an overwrite prompt; the
# java-temurin block in ~/.bashrc is replaced on every run.
# Requirements: sudo access, curl, tar, ca-certificates (installed automatically via apt).

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

BASE_DIR="/opt/java/temurin"
VERSIONS=("8:jdk" "8:jre" "17:jdk" "17:jre" "21:jdk" "21:jre" "25:jdk" "25:jre")
BASHRC="$HOME/.bashrc"
MARK_START="# >>> java-temurin >>>"
MARK_END="# <<< java-temurin <<<"
TS="$(date +%Y%m%d_%H%M%S)"

# Newest JDK — will be the only uncommented JAVA_HOME
DEFAULT_V="25"
DEFAULT_TYPE="jdk"

echo "----------------------Setup----------------------"
echo "[*] Updating package index..."
sudo apt-get update -q

echo "[*] Installing required packages: curl tar ca-certificates"
sudo apt-get install -y curl tar ca-certificates
echo "[+] Packages installed."

echo "----------------Java Installation----------------"
sudo mkdir -p "$BASE_DIR"

for item in "${VERSIONS[@]}"; do
    V="${item%%:*}"
    TYPE="${item##*:}"
    TARGET_DIR="$BASE_DIR/java-$V-$TYPE"

    echo ""
    echo "[*] Java $V ($TYPE) -> $TARGET_DIR"

    if [[ -d "$TARGET_DIR" ]]; then
        read -rp "[?] Directory already exists. Overwrite? [y/N]: " REPLY
        case "${REPLY,,}" in
            y|yes)
                echo "[*] Removing existing directory..."
                sudo rm -rf "$TARGET_DIR"
                ;;
            n|no|"")
                echo "[i] Skipped."
                continue
                ;;
            *)
                echo "[!] Invalid input -> skipping ..."
                continue
                ;;
        esac
    fi

    sudo mkdir -p "$TARGET_DIR"
    API_URL="https://api.adoptium.net/v3/binary/latest/$V/ga/linux/x64/$TYPE/hotspot/normal/eclipse?project=jdk"

    echo "[*] Downloading and extracting..."
    if curl -sL -f "$API_URL" | sudo tar -xz -C "$TARGET_DIR" --strip-components=1; then
        echo "[+] Installed: $TARGET_DIR"
    else
        echo "[!] Failed to download or extract Java $V $TYPE"
        sudo rm -rf "$TARGET_DIR"
    fi
done

echo ""
echo "---------------------.bashrc---------------------"

# Remove existing block if present (idempotent re-run)
if grep -qF "$MARK_START" "$BASHRC" 2>/dev/null; then
    echo "[*] Removing existing java-temurin block..."
    awk -v s="$MARK_START" -v e="$MARK_END" '
        $0 == s { skip=1 }
        skip { if ($0 == e) skip=0; next }
        { print }
    ' "$BASHRC" > "${BASHRC}.tmp" && mv "${BASHRC}.tmp" "$BASHRC"
fi

echo "[*] Writing java-temurin block to ~/.bashrc..."
{
    echo ""
    echo "$MARK_START"
    echo "# Java Temurin"
    for item in "${VERSIONS[@]}"; do
        V="${item%%:*}"
        TYPE="${item##*:}"
        DIR="$BASE_DIR/java-$V-$TYPE"
        if [[ "$V" == "$DEFAULT_V" && "$TYPE" == "$DEFAULT_TYPE" ]]; then
            echo "export JAVA_HOME=$DIR"
        else
            echo "# export JAVA_HOME=$DIR"
        fi
    done
    echo "export PATH=\$JAVA_HOME/bin:\$PATH"
    echo "$MARK_END"
} >> "$BASHRC"

echo "[+] ~/.bashrc updated."

echo ""
echo "================================================="
echo "               Setup Complete!                   "
echo "================================================="
echo "[INFO] Install dir : $BASE_DIR"
echo "       Contents    :"
ls -1 "$BASE_DIR" 2>/dev/null | sed 's/^/             /'
echo "       Default     : $BASE_DIR/java-${DEFAULT_V}-${DEFAULT_TYPE}"
echo "       ~/.bashrc   : $MARK_START block added"
echo ""
echo "       Apply changes now with: source ~/.bashrc"
