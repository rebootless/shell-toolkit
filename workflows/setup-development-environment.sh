#!/bin/bash

# ---DOC-START---
# summary: Install a full C++/Python/PHP/Node dev environment + LSP servers in one step.
# description: |
#   Installs a complete development environment by chaining scripts from `install/`.
#
#   - Runs in order: `install-cpp.sh`, `install-python.sh`, `install-php.sh`, `install-npm.sh`
#   - Then installs `install-bash-language-server.sh`, `install-markdown-language-server.sh`, `install-python-language-server.sh` and `install-clang-language-server.sh`
# sudo: false
# interactive: false
# idempotent: true
# dependencies: install/install-cpp.sh, install/install-python.sh, install/install-php.sh, install/install-npm.sh, lsp/lsp-install-bash-language-server.sh, lsp/lsp-install-markdown-language-server.sh, lsp/lsp-install-python-language-server.sh, lsp/lsp-install-clang-language-server.sh
# ---DOC-END---

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
CLI_DIR="$(cd "$SCRIPT_DIR/../install" && pwd)"
LSP_DIR="$(cd "$SCRIPT_DIR/../lsp" && pwd)"

echo "Running CLI installation scripts..."
run_root_scripts "$CLI_DIR" \
    install-cpp.sh \
    install-python.sh \
    install-php.sh \
    install-npm.sh

echo "Running LSP installation scripts..."
run_user_scripts "$LSP_DIR" \
    lsp-install-bash-language-server.sh \
    lsp-install-markdown-language-server.sh \
    lsp-install-python-language-server.sh
run_root_scripts "$LSP_DIR" \
    lsp-install-clang-language-server.sh

echo "Done."
