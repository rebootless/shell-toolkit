#!/bin/bash

set -euo pipefail

MARK_START="# >>> bash-language-server >>>"
MARK_END="# <<< bash-language-server <<<"

mkdir -p "$HOME/.local/npm"

npm config set prefix "$HOME/.local/npm"

# --- bashrc ---
grep -qF "$MARK_START" "$HOME/.bashrc" || cat >> "$HOME/.bashrc" <<EOF

$MARK_START
export PATH="\$HOME/.local/npm/bin:\$PATH"
$MARK_END
EOF

# --- profile ---
grep -qF "$MARK_START" "$HOME/.profile" || cat >> "$HOME/.profile" <<EOF

$MARK_START
export PATH="\$HOME/.local/npm/bin:\$PATH"
$MARK_END
EOF

npm install -g bash-language-server

echo "[NOTE] Log out and log back into your session"
echo "       (or reboot) for the updated PATH to take effect."
