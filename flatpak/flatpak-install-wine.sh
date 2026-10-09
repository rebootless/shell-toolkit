#!/bin/bash

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DEBIAN_FRONTEND=noninteractive

APP_ID="org.winehq.Wine"
BASHRC="$HOME/.bashrc"

MARK_START="# >>> wine-flatpak >>>"
MARK_END="# <<< wine-flatpak <<<"

echo "==> Installing Wine via Flatpak"

if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak is not installed, skipping..."
    exit 0
fi

echo "Installing Wine via Flatpak..."

flatpak install -y flathub "$APP_ID"

echo ""
echo "==> Configuring Wine shell aliases"

if grep -qF "$MARK_START" "$BASHRC" 2>/dev/null; then
    echo "Removing existing Wine configuration block..."

    awk \
        -v start="$MARK_START" \
        -v end="$MARK_END" '
        $0 == start {
            remove=1
            next
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
# Flatpak Wine

alias wine='flatpak run --command=wine $APP_ID'
alias winecfg='flatpak run --command=winecfg $APP_ID'
alias wineconsole='flatpak run --command=wineconsole $APP_ID'
alias winecmd='flatpak run --command=wine $APP_ID cmd'
alias winetricks='flatpak run --command=winetricks $APP_ID'
$MARK_END
EOF

echo ""
echo "Wine installed"

echo ""
echo "Application:"
echo "  $APP_ID"

echo ""
echo "Direct commands:"
echo "  flatpak run $APP_ID"
echo "  flatpak run --command=wine $APP_ID <program.exe>"
echo "  flatpak run --command=winecfg $APP_ID"
echo "  flatpak run --command=wineconsole $APP_ID"
echo "  flatpak run --command=wine $APP_ID cmd"
echo "  flatpak run --command=winetricks $APP_ID"

echo ""
echo "Shell aliases:"
echo "  wine <program.exe>"
echo "  winecfg"
echo "  wineconsole"
echo "  winecmd"
echo "  winetricks"

echo ""
echo "Apply aliases to the current shell:"
echo "  source ~/.bashrc"

echo ""
echo "Installed apps:"
flatpak list | grep -i Wine || true
