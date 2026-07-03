#!/bin/bash

set -euo pipefail

MARK_START="# >>> python-language-server >>>"
MARK_END="# <<< python-language-server <<<"

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# --- install pylsp ---
if ! command -v "$INSTALL_DIR/pylsp" >/dev/null 2>&1; then
    echo "[*] Installing python-lsp-server (pylsp)..."

    PIP_LOG="$(mktemp)"
    trap 'rm -f "$PIP_LOG"' EXIT

    if ! python3 -m pip install --user --quiet "python-lsp-server[all]" >"$PIP_LOG" 2>&1; then
        if grep -q "externally-managed-environment" "$PIP_LOG"; then
            echo "[*] Externally-managed environment detected, retrying with --break-system-packages..."
            python3 -m pip install --user --break-system-packages --quiet "python-lsp-server[all]"
        else
            cat "$PIP_LOG"
            exit 1
        fi
    fi
else
    echo "[*] pylsp already installed, skipping."
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

echo "[NOTE] Log out and log back into your session"
echo "       (or reboot) for the updated PATH to take effect."
