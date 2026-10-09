#!/bin/bash

# ---DOC-START---
# summary: Eclipse Temurin JDK/JRE installer (v8, 17, 21, 25).
# description: |
#   Downloads and installs multiple Eclipse Temurin (Adoptium) JDK/JRE builds.
#   Install path: `/opt/java/temurin/`
#
#   - Supported versions: 8, 17, 21, 25
#   - Downloads both JDK and JRE variants
#   - Updates the current user's shell configuration
#   - Requires sudo only for system-wide installation
#
#   Usage:
#     ./install-temurin.sh
#     ./install-temurin.sh --force
#
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

BASE_DIR="/opt/java/temurin"

VERSIONS=(
    "8:jdk"
    "8:jre"
    "17:jdk"
    "17:jre"
    "21:jdk"
    "21:jre"
    "25:jdk"
    "25:jre"
)

DEFAULT_V="25"
DEFAULT_TYPE="jdk"

BASHRC="$HOME/.bashrc"

MARK_START="# >>> java-temurin >>>"
MARK_END="# <<< java-temurin <<<"

FORCE=false

if [[ "${1:-}" == "--force" ]]; then
    FORCE=true
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required."
    exit 1
fi

echo "==> Installing dependencies"

sudo apt-get update -q
sudo apt-get install -y \
    curl \
    tar \
    ca-certificates

echo ""
echo "==> Installing Eclipse Temurin"

sudo mkdir -p "$BASE_DIR"
for item in "${VERSIONS[@]}"; do

    VERSION="${item%%:*}"
    TYPE="${item##*:}"
    TARGET_DIR="$BASE_DIR/java-$VERSION-$TYPE"

    echo ""
    echo "Java $VERSION ($TYPE)"

    if [[ -d "$TARGET_DIR" ]]; then
        if [[ "$FORCE" == true ]]; then
            echo "Removing existing installation..."
            sudo rm -rf "$TARGET_DIR"
        else
            echo "Already installed: $TARGET_DIR"
            echo "Skipping."
            continue
        fi
    fi

    sudo mkdir -p "$TARGET_DIR"
    API_URL="https://api.adoptium.net/v3/binary/latest/$VERSION/ga/linux/x64/$TYPE/hotspot/normal/eclipse?project=jdk"
    echo "Downloading..."
    TMP_FILE="$(mktemp)"

    if curl -fsSL "$API_URL" -o "$TMP_FILE"; then
        sudo tar \
            -xzf "$TMP_FILE" \
            -C "$TARGET_DIR" \
            --strip-components=1
        echo "Installed: $TARGET_DIR"
    else
        echo "Failed downloading Java $VERSION $TYPE"
        sudo rm -rf "$TARGET_DIR"
    fi
    rm -f "$TMP_FILE"
done

echo ""
echo "==> Updating shell configuration"

if grep -qF "$MARK_START" "$BASHRC" 2>/dev/null; then
    echo "Removing old configuration block..."
    awk \
        -v start="$MARK_START" \
        -v end="$MARK_END" '
        $0 == start {
            remove=1
        }
        remove && $0 == end {
            remove=0
            next
        }
        !remove {
            print
        }
    ' "$BASHRC" > "$BASHRC.tmp"
    mv "$BASHRC.tmp" "$BASHRC"
fi

cat >> "$BASHRC" <<EOF

$MARK_START
# Eclipse Temurin Java versions

export JAVA_8_JDK="$BASE_DIR/java-8-jdk"
export JAVA_8_JRE="$BASE_DIR/java-8-jre"

export JAVA_17_JDK="$BASE_DIR/java-17-jdk"
export JAVA_17_JRE="$BASE_DIR/java-17-jre"

export JAVA_21_JDK="$BASE_DIR/java-21-jdk"
export JAVA_21_JRE="$BASE_DIR/java-21-jre"

export JAVA_25_JDK="$BASE_DIR/java-25-jdk"
export JAVA_25_JRE="$BASE_DIR/java-25-jre"

export JAVA_HOME="$BASE_DIR/java-$DEFAULT_V-$DEFAULT_TYPE"
export PATH="\$JAVA_HOME/bin:\$PATH"

$MARK_END
EOF

echo ""
echo "==> Summary"

echo ""
echo "Install directory:"
echo "  $BASE_DIR"

echo ""
echo "Installed versions:"

if [[ -d "$BASE_DIR" ]]; then
    ls -1 "$BASE_DIR" | sed 's/^/  /'
fi

echo ""
echo "Default JAVA_HOME:"
echo "  $BASE_DIR/java-$DEFAULT_V-$DEFAULT_TYPE"

echo ""
echo "Apply changes:"
echo "  source ~/.bashrc"

echo ""
echo "Temurin installation completed."
