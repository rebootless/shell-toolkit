#!/bin/bash

# ---DOC-START---
# summary: Install ranger_devicons for ranger.
# description: |
#   Installs [ranger_devicons](https://github.com/alexanderjeurissen/ranger_devicons) into the current user's ranger configuration.
#   Install path: `$HOME/.config/ranger/plugins/ranger_devicons`
#
#   - Downloads the latest plugin archive from GitHub.
#   - Enables `default_linemode devicons` in `$HOME/.config/ranger/rc.conf`.
#   - Requires a Nerd Font configured in your terminal.
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if ! command -v ranger >/dev/null 2>&1; then
    echo "ranger is not installed."
    echo "Please install ranger first."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required."
    exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
    echo "tar is required."
    exit 1
fi

echo "==> Installing ranger_devicons"

CONFIG_DIR="$HOME/.config/ranger"
PLUGINS_DIR="$CONFIG_DIR/plugins"
PLUGIN_DIR="$PLUGINS_DIR/ranger_devicons"
RC_CONF="$CONFIG_DIR/rc.conf"
ETC_RC_CONF="/etc/ranger/rc.conf"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$PLUGINS_DIR"

if [[ -d "$PLUGIN_DIR" ]]; then
    echo "Updating ranger_devicons..."
    rm -rf "$PLUGIN_DIR"
else
    echo "Installing ranger_devicons..."
fi

curl -fsSL \
    https://github.com/alexanderjeurissen/ranger_devicons/archive/refs/heads/main.tar.gz \
    | tar -xz -C "$TMP_DIR"

EXTRACTED_DIR="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)"

if [[ -z "$EXTRACTED_DIR" ]]; then
    echo "Failed to extract ranger_devicons."
    exit 1
fi

mv "$EXTRACTED_DIR" "$PLUGIN_DIR"

mkdir -p "$CONFIG_DIR"

if [[ ! -f "$RC_CONF" ]]; then
    if [[ -f "$ETC_RC_CONF" ]]; then
        echo "No rc.conf found, copying default from $ETC_RC_CONF..."
        cp "$ETC_RC_CONF" "$RC_CONF"
    else
        echo "No rc.conf found in $CONFIG_DIR or $ETC_RC_CONF, creating empty one..."
        touch "$RC_CONF"
    fi
fi

if ! grep -qxF "default_linemode devicons" "$RC_CONF"; then
    echo "default_linemode devicons" >> "$RC_CONF"
fi

echo ""
echo "==> Summary"

echo ""
echo "ranger_devicons installed successfully."

echo ""
echo "to display icons correctly, install a Nerd Font:"
echo "  https://www.nerdfonts.com/ (e.g. JetBrainsMono)"
