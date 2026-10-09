#!/bin/bash

# ---DOC-START---
# summary: Install marksman Markdown language server for editor/IDE LSP integration.
# description: |
#   Installs `marksman` into for the current user.
#   Install path: `$HOME/.local/bin`
#
#   - Adds `~/.local/bin` to `.bashrc` and `.profile`
#   - Idempotent — skips installation if marksman is already present
#   - Requires curl to be available
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root."
    echo "Run it as a regular user."
    exit 1
fi

echo "==> Installing Markdown LSP"

MARK_START="# >>> markdown-language-server >>>"
MARK_END="# <<< markdown-language-server <<<"

INSTALL_DIR="$HOME/.local/bin"

mkdir -p "$INSTALL_DIR"

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required but not installed."
    echo "Install it with: sudo apt install curl"
    exit 1
fi

if [[ ! -x "$INSTALL_DIR/marksman" ]]; then
    echo "Installing marksman (Markdown LSP)..."

    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT

    cd "$TMP_DIR"

    curl -L -o marksman \
        https://github.com/artempyanykh/marksman/releases/latest/download/marksman-linux-x64

    chmod +x marksman
    mv marksman "$INSTALL_DIR/marksman"
else
    echo "marksman already installed, skipping."
fi

grep -qF "$MARK_START" "$HOME/.bashrc" || cat >> "$HOME/.bashrc" <<EOF

$MARK_START
export PATH="\$HOME/.local/bin:\$PATH"
$MARK_END
EOF

grep -qF "$MARK_START" "$HOME/.profile" || cat >> "$HOME/.profile" <<EOF

$MARK_START
export PATH="\$HOME/.local/bin:\$PATH"
$MARK_END
EOF

echo ""
echo "Markdown LSP installed successfully."

echo ""
echo "Log out and log back into your session"
echo "(or reboot) for the updated PATH to take effect."
