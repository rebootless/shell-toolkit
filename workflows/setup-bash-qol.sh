#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$(cd "$SCRIPT_DIR/../standalone/apt/cli" && pwd)"

MARK_START="# >>> bash-qol >>>"
MARK_END="# <<< bash-qol <<<"
BASHRC="$HOME/.bashrc"
INPUTRC="$HOME/.inputrc"
TS="$(date +%Y%m%d_%H%M%S)"

echo "---------------Installing packages---------------"

for script in install-bash-completion.sh install-fzf.sh install-zoxide.sh install-ripgrep.sh install-bat.sh install-eza.sh; do
    if [[ ! -f "$CLI_DIR/$script" ]]; then
        echo "[!] Missing $script in $CLI_DIR"
        exit 1
    fi
    echo "[*] Running $script"
    sudo bash "$CLI_DIR/$script"
done

echo "[+] Packages installed."

echo "--------------Configuring ~/.bashrc--------------"

if [[ -f "$BASHRC" ]]; then
    cp "$BASHRC" "${BASHRC}.bak.${TS}"
    echo "[i] ~/.bashrc backed up to ${BASHRC}.bak.${TS}"
    if grep -qF "$MARK_START" "$BASHRC"; then
        sed -i "/${MARK_START}/,/${MARK_END}/d" "$BASHRC"
        echo "[i] Removed previous managed block."
    fi
else
    touch "$BASHRC"
    echo "[i] No existing ~/.bashrc found, creating new one."
fi

{
    echo ""
    echo "$MARK_START"
    cat <<EOF
# History
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoredups:erasedups
HISTIGNORE="ls:l:ll:pwd:clear:history"
shopt -s histappend
PROMPT_COMMAND="history -a; history -n\${PROMPT_COMMAND:+; \$PROMPT_COMMAND}"

# Completion
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# Improved tab behavior
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'TAB:menu-complete'

# History search with arrow keys
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# Useful shell options
shopt -s autocd
shopt -s cdspell
shopt -s checkwinsize
shopt -s dirspell
shopt -s globstar

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias update='sudo apt update && sudo apt upgrade'
alias ports='ss -tulpen'
alias dfh='df -h'
EOF
    cat <<'EOF'

# zoxide (smart cd)
eval "$(zoxide init bash)"

# fzf (Ctrl+R history search)
if fzf --bash >/dev/null 2>&1; then
    eval "$(fzf --bash)"
else
    [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
    [ -f /usr/share/doc/fzf/examples/completion.bash ]   && . /usr/share/doc/fzf/examples/completion.bash
fi
EOF
    echo "$MARK_END"
} >> "$BASHRC"

echo "[+] ~/.bashrc updated."

echo "--------------Configuring ~/.inputrc-------------"

if [[ -f "$INPUTRC" ]]; then
    cp "$INPUTRC" "${INPUTRC}.bak.${TS}"
    echo "[i] ~/.inputrc backed up to ${INPUTRC}.bak.${TS}"
fi

cat > "$INPUTRC" <<'EOF'
set editing-mode emacs

set colored-stats On
set colored-completion-prefix On

set completion-ignore-case On
set show-all-if-ambiguous On
set menu-complete-display-prefix On

set mark-symlinked-directories On
set visible-stats On

"\e[A": history-search-backward
"\e[B": history-search-forward
EOF

echo "[+] ~/.inputrc written."

echo "================================================="
echo "                     SUMMARY                     "
echo "================================================="
echo "[INFO] Installed: bash-completion, fzf, zoxide, ripgrep, bat, eza"
echo "       Packages installed via standalone/apt/cli/install-*.sh"
echo "       ~/.bashrc managed block: $MARK_START ... $MARK_END"
echo "       ~/.inputrc: replaced (backup saved if it existed)"
echo "       For oh-my-bash, run setup-oh-my-bash.sh separately (it edits ~/.bashrc)"
echo ""
echo "---------------------Aliases---------------------"
printf "  %-10s %-20s %s\n" "ll"     "ls -lah"               "long list, all files, human sizes"
printf "  %-10s %-20s %s\n" "la"     "ls -A"                 "all files except . and .."
printf "  %-10s %-20s %s\n" "l"      "ls -CF"                "compact columns with type marks"
printf "  %-10s %-20s %s\n" "grep"   "grep --color=auto"     "highlight matches"
printf "  %-10s %-20s %s\n" "update" "apt update && upgrade" "system update"
printf "  %-10s %-20s %s\n" "ports"  "ss -tulpen"            "listening ports + processes"
printf "  %-10s %-20s %s\n" "dfh"    "df -h"                 "disk usage, human-readable"
echo ""
echo "-------------------Keybindings-------------------"
printf "  %-12s %s\n" "Tab"     "cycle through completions (menu-complete)"
printf "  %-12s %s\n" "Up/Down" "search history by text already on the line"
printf "  %-12s %s\n" "Ctrl+R"  "fuzzy search through command history (fzf)"
echo "  completion is case-insensitive, colored, shows all matches"
echo ""
echo "------------------Shell behavior-----------------"
printf "  %-14s %s\n" "autocd"       "bare directory path -> cd into it"
printf "  %-14s %s\n" "cdspell"      "autocorrects minor 'cd' typos"
printf "  %-14s %s\n" "dirspell"     "autocorrects typos in path completion"
printf "  %-14s %s\n" "globstar"     "'**' matches files recursively"
printf "  %-14s %s\n" "checkwinsize" "terminal size updates after each command"
echo ""
echo "---------------------History---------------------"
echo "  100000 commands in memory / 200000 in ~/.bash_history"
echo "  duplicates are not stored (ignoredups:erasedups)"
echo "  ls, l, ll, pwd, clear, history are never stored"
echo "  history is shared live between open terminal sessions"
echo ""
echo "--------------------New tools--------------------"
printf "  %-12s %s\n" "z <name>"   "zoxide: jump to a frequent directory"
printf "  %-12s %s\n" "zi"         "zoxide: interactive directory picker"
printf "  %-12s %s\n" "rg <text>"  "ripgrep: fast recursive text search"
printf "  %-12s %s\n" "bat <file>" "syntax-highlighted 'cat'"
printf "  %-12s %s\n" "eza"    "modern 'ls' (icons, git status, tree)"
printf "  %-12s %s\n" "eza -T" "tree view of a directory"
echo "================================================="
echo ""
echo "[i] Apply changes now with: source ~/.bashrc"
echo ""
echo "[TIP] to display icons correctly, install a Nerd Font"
echo "      https://www.nerdfonts.com/ (e.g. JetBrainsMono)"
