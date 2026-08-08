#!/bin/bash

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

run_root_scripts() {
    local dir="$1"
    shift
    for script in "$@"; do
        echo "Running $script"
        sudo bash "$dir/$script"
    done
}

run_user_scripts() {
    local dir="$1"
    shift
    for script in "$@"; do
        echo "Running $script"
        bash "$dir/$script"
    done
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$(cd "$SCRIPT_DIR/../standalone/install/apt/cli" && pwd)"
LSP_DIR="$(cd "$SCRIPT_DIR/../standalone/install/lsp" && pwd)"

echo "Running CLI installation scripts..."
run_root_scripts "$CLI_DIR" \
    install-cpp.sh \
    install-python.sh \
    install-php.sh \
    install-npm.sh

echo "Running LSP installation scripts..."
run_user_scripts "$LSP_DIR" \
    install-bash-language-server.sh \
    install-markdown-language-server.sh \
    install-python-language-server.sh

echo "Done."
