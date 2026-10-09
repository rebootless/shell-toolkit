#!/bin/bash

# ---DOC-START---
# summary: Install Git and perform the initial Git configuration.
# description: |
#   Sets up a complete Git environment by chaining standalone scripts.
#
#   - Installs Git from the distribution repositories.
#   - Runs the Git bootstrap configuration.
#
#   Example:
#     ./setup-git.sh \
#         --username USERNAME \
#         --email EMAIL \
#         --default-branch main \
#         --token ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
#         --store-credentials
# sudo: false
# interactive: true
# idempotent: true
# dependencies: git/install-git.sh, git/bootstrap-git.sh
# ---DOC-END---

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_DIR="$(cd "$SCRIPT_DIR/../git" && pwd)"
GIT_DIR="$(cd "$SCRIPT_DIR/../git" && pwd)"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install Git and bootstrap GitHub configuration.

Options:
  --username NAME          Git user name
  --email EMAIL            Git email
  --token TOKEN            GitHub Personal Access Token (ghp_...)
  --default-branch NAME    Default branch (default: main)
  --store-credentials      Store GitHub credentials in ~/.git-credentials
  -h, --help               Show this help
EOF
}

if [[ $# -eq 0 ]]; then
    usage >&2
    exit 1
fi

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

run_root_script() {
    local script="$1"
    shift

    if [[ ! -f "$script" ]]; then
        echo "Missing $script"
        return 1
    fi

    echo "Running $(basename "$script")"
    sudo bash "$script" "$@"
}

run_user_script() {
    local script="$1"
    shift

    if [[ ! -f "$script" ]]; then
        echo "Missing $script"
        return 1
    fi

    echo "Running $(basename "$script")"
    bash "$script" "$@"
}

echo "Running git setup..."

run_root_script \
    "$INSTALL_DIR/install-git.sh"

run_user_script \
    "$GIT_DIR/bootstrap-git.sh" \
    "$@"

echo "Done."
