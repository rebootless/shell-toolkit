#!/bin/bash

# Colors for formatted output (using ANSI-C quoting)
C_CYAN=$'\e[1;36m'
C_GREEN=$'\e[1;32m'
C_YELLOW=$'\e[1;33m'
C_MAG=$'\e[1;35m'
C_RESET=$'\e[0m'

# Determine the correct command for bat (Debian ships it as batcat)
BAT_CMD="bat"
if command -v batcat >/dev/null 2>&1; then
    BAT_CMD="batcat"
fi

echo -e "${C_CYAN}=====================================================${C_RESET}"
echo -e "${C_CYAN}                    BASH-QOL-DEMO                    ${C_RESET}"
echo -e "${C_CYAN}=====================================================${C_RESET}\n"

# Create a temporary sandbox directory
DEMO_DIR=$(mktemp -d -t terminal-demo-XXXXXX)
cd "$DEMO_DIR"

echo -e "${C_YELLOW}[*] Creating test files for the demonstration...${C_RESET}"
mkdir -p project/src project/tests project/docs
echo "print('Hello, Bash Coding Partner!')" > project/src/main.py
echo "def calculate(a, b): return a + b # TODO: add math logic" > project/src/utils.py
echo "import pytest" > project/tests/test_main.py
echo "# Documentation" > project/docs/readme.md
echo "TODO: Write tests!" > project/TODO.txt

sleep 1

# 1. eza demonstration
echo -e "\n${C_GREEN}>>> 1. EZA (A modern replacement for ls) ${C_RESET}"
echo -e "${C_MAG}$ eza -lah --icons project/${C_RESET}"
eza -lah --icons project/
echo ""
echo -e "${C_MAG}$ eza --tree --icons project/${C_RESET}"
eza --tree --icons project/

# Wait for user input before proceeding
read -n 1 -s -r -p "Press any key to continue..."
echo ""

# 2. bat demonstration
echo -e "\n${C_GREEN}>>> 2. BAT (cat clone with syntax highlighting and Git integration) ${C_RESET}"
echo -e "${C_MAG}$ $BAT_CMD project/src/utils.py${C_RESET}"
$BAT_CMD project/src/utils.py

# Wait for user input before proceeding
read -n 1 -s -r -p "Press any key to continue..."
echo ""

# 3. ripgrep demonstration
echo -e "\n${C_GREEN}>>> 3. RIPGREP (Ultra-fast recursive text search) ${C_RESET}"
echo -e "${C_MAG}$ rg \"TODO\" project/${C_RESET}"
rg "TODO" project/

# Wait for user input before proceeding
read -n 1 -s -r -p "Press any key to continue..."
echo ""

# 4. Interactive features explanation
echo -e "\n${C_GREEN}>>> 4. INTERACTIVE FEATURES (Try them yourself after the tour!) ${C_RESET}"
cat << EOF
autocd: Just type the directory path without 'cd'.
   ${C_MAG}$ /var/log${C_RESET} -> automatically changes directory to /var/log

zoxide (Smart cd): It remembers your most used directories.
   ${C_MAG}$ z pro${C_RESET} -> instantly jumps to ~/Documents/project
   ${C_MAG}$ zi${C_RESET}    -> opens an interactive directory picker

fzf (History search):
   Press ${C_MAG}Ctrl + R${C_RESET} and start typing. It finds commands even with typos!

Aliases:
   ${C_MAG}$ ll${C_RESET}    -> beautiful detailed list (eza or ls -lah)
   ${C_MAG}$ ports${C_RESET} -> shows listening ports and processes (ss -tulpen)
   ${C_MAG}$ dfh${C_RESET}   -> human-readable disk usage
EOF

echo -e "\n${C_YELLOW}[*] Cleaning up: removing test files...${C_RESET}"
cd /tmp
rm -rf "$DEMO_DIR"

echo -e "${C_CYAN}Tour completed! Happy coding!${C_RESET}"

echo "TIP:"
echo "To display emojis correctly, you need to install a Nerd Font"
echo "(https://www.nerdfonts.com/), for example: JetBrainsMono"
