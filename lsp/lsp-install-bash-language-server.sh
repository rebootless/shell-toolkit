#!/bin/bash

# ---DOC-START---
# summary: Install bash-language-server via npm for editor/IDE LSP integration.
# description: |
#   Installs [bash-language-server](https://github.com/bash-lsp/bash-language-server) via npm.
#   Install path: `$HOME/.local/npm`
#   Marker block path: `~/.bashrc` `~/.profile`
#
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

echo "==> Installing Bash LSP"

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
echo ""
echo "Bash LSP installed successfully."

echo ""
echo "Log out and log back into your session"
echo "(or reboot) for the updated PATH to take effect."
