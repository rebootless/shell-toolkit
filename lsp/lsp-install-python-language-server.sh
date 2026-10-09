#!/bin/bash

set -euo pipefail

echo "==> Installing Python LSP"

MARK_START="# >>> python-language-server >>>"
MARK_END="# <<< python-language-server <<<"

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# --- install pylsp ---
if ! command -v pylsp >/dev/null 2>&1; then
    echo "Installing python-lsp-server (pylsp)..."
    pipx install "python-lsp-server[all]"
else
    echo "pylsp already installed, skipping."
fi

# --- bashrc ---
grep -qF "$MARK_START" "$HOME/.bashrc" || cat >> "$HOME/.bashrc" <<EOF

$MARK_START
export PATH="\$HOME/.local/bin:\$PATH"
$MARK_END
EOF

# --- profile ---
grep -qF "$MARK_START" "$HOME/.profile" || cat >> "$HOME/.profile" <<EOF

$MARK_START
export PATH="\$HOME/.local/bin:\$PATH"
$MARK_END
EOF

echo ""
echo "Python LSP installed successfully."

echo ""
echo "Log out and log back into your session"
echo "(or reboot) for the updated PATH to take effect."
