#!/bin/bash

# ---DOC-START---
# summary: Install Tor Browser via the official Tor Project apt repository.
# description: |
#   Installs [Tor Browser](https://www.torproject.org) via the official Tor Project apt repository.
#   Install path: `$HOME/.local/bin`
# sudo: true
# interactive: false
# idempotent: mostly
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

echo "==> Installing Tor Browser"

TMP="/tmp/torbrowser"
INSTALL_DIR="$HOME/.local/share/tor-browser"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"

echo "Checking dependencies..."

REQUIRED_PKGS=(wget curl gnupg tar xz-utils grep ca-certificates)

MISSING_PKGS=()

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [[ ${#MISSING_PKGS[@]} -ne 0 ]]; then
    echo "Missing packages: ${MISSING_PKGS[*]}"
    echo "Installing via apt..."

    if [[ $EUID -ne 0 ]]; then
        sudo apt update
        sudo apt install -y "${MISSING_PKGS[@]}"
    else
        apt update
        apt install -y "${MISSING_PKGS[@]}"
    fi
else
    echo "All dependencies already installed"
fi

echo "Installing Tor Browser in USERSPACE"

mkdir -p "$TMP" "$INSTALL_DIR" "$BIN_DIR" "$APPS_DIR"

echo "Determining latest Tor Browser version..."

VERSION="$(curl -fsSL https://dist.torproject.org/torbrowser/ \
    | grep -oP '(?<=href=")[0-9]+\.[0-9]+\.[0-9]+(?=/")' \
    | sort -V \
    | tail -n1 | tr -d '[:space:]')"

if [[ -z "$VERSION" ]]; then
    echo "Failed to determine latest version"
    exit 1
fi

echo "Latest version: $VERSION"

BASE_URL="https://dist.torproject.org/torbrowser/${VERSION}"

TAR="tor-browser-linux-x86_64-${VERSION}.tar.xz"
SIG="${TAR}.asc"

echo "Checking remote file availability..."

if ! curl -fI "$BASE_URL/$TAR" >/dev/null 2>&1; then
    echo "Remote file not found: $BASE_URL/$TAR"
    exit 1
fi

echo "Downloading Tor Browser..."

wget -O "$TMP/$TAR" "$BASE_URL/$TAR"
wget -O "$TMP/$SIG" "$BASE_URL/$SIG"

echo "Importing signing key..."

gpg --auto-key-locate nodefault,wkd \
    --locate-keys torbrowser@torproject.org

echo "Verifying signature..."

gpg --verify "$TMP/$SIG" "$TMP/$TAR"

echo "Signature OK"

echo "Installing to $INSTALL_DIR..."

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

tar -xJf "$TMP/$TAR" -C "$INSTALL_DIR" --strip-components=1

echo "Creating launcher..."

cat > "$BIN_DIR/tor-browser" <<EOF
#!/bin/sh
cd "$INSTALL_DIR"
exec ./start-tor-browser.desktop "\$@"
EOF

chmod +x "$BIN_DIR/tor-browser"

echo "Creating desktop entry..."

cat > "$APPS_DIR/tor-browser.desktop" <<EOF
[Desktop Entry]
Name=Tor Browser
Exec=$BIN_DIR/tor-browser
Icon=tor
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
Terminal=false
EOF

echo "Refreshing desktop database..."

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
fi

echo "Cleaning up..."
rm -rf "$TMP"

echo ""
echo "==> Summary"

echo ""
echo "Tor Browser installed in userspace:"
echo "$INSTALL_DIR"
echo "Run:"
echo "  tor-browser"
echo "Or open it from application menu"
