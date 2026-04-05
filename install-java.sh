#!/bin/bash

echo "Updating system packages..."
sudo apt update

echo "Installing required dependencies..."
sudo apt install -y curl tar ca-certificates

BASE_DIR="$HOME/Java/Temurin"
VERSIONS=("8:jdk" "8:jre" "17:jdk" "17:jre" "21:jdk" "21:jre" "25:jdk" "25:jre")

echo "Starting Java setup"
mkdir -p "$BASE_DIR"

for item in "${VERSIONS[@]}"; do
    V="${item%%:*}"
    TYPE="${item##*:}"
    TARGET_DIR="$BASE_DIR/java-$V-$TYPE"

    echo ">>> Processing Java $V ($TYPE)..."

    API_URL="https://api.adoptium.net/v3/binary/latest/$V/ga/linux/x64/$TYPE/hotspot/normal/eclipse?project=jdk"

    mkdir -p "$TARGET_DIR"

    echo "    Downloading and extracting..."

    if curl -sL -f "$API_URL" | tar -xz -C "$TARGET_DIR" --strip-components=1; then
        echo "    [OK] Successfully installed to $TARGET_DIR"
    else
        echo "    [!] Error: Failed to download or extract Java $V $TYPE"
        # Clean up empty directory on failure
        rm -rf "$TARGET_DIR"
    fi
done

echo "--------------------------------"
echo "Java installation process finished."
ls -l "$BASE_DIR"
