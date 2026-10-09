#!/bin/bash

# ---DOC-START---
# summary: Bootstrap Git configuration for a GitHub account.
# description: |
#   Configures Git user identity and optionally stores GitHub HTTPS
#   credentials for automatic authentication.
#
#   - Sets global user name and email.
#   - Sets the default branch name.
#   - Optionally enables credential.helper store.
#   - Optionally stores a GitHub Personal Access Token (PAT).
# sudo: false
# interactive: false
# idempotent: true
# dependencies: none
# ---DOC-END---

set -euo pipefail

USERNAME=""
EMAIL=""
TOKEN=""
DEFAULT_BRANCH="main"
STORE_CREDENTIALS=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Bootstrap Git for GitHub.

Options:
  --username NAME          Git user name
  --email EMAIL            Git email
  --token TOKEN            GitHub Personal Access Token (ghp_...)
  --default-branch NAME    Default branch (default: main)
  --store-credentials      Store GitHub credentials in ~/.git-credentials
  -h, --help               Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --username)
            USERNAME="$2"
            shift 2
            ;;
        --email)
            EMAIL="$2"
            shift 2
            ;;
        --token)
            TOKEN="$2"
            shift 2
            ;;
        --default-branch)
            DEFAULT_BRANCH="$2"
            shift 2
            ;;
        --store-credentials)
            STORE_CREDENTIALS=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if ! command -v git >/dev/null 2>&1; then
    echo "git is not installed."
    exit 1
fi

if [[ -z "$USERNAME" ]]; then
    echo "--username is required."
    exit 1
fi

if [[ -z "$EMAIL" ]]; then
    echo "--email is required."
    exit 1
fi

git config --global user.name "$USERNAME"
git config --global user.email "$EMAIL"
git config --global init.defaultBranch "$DEFAULT_BRANCH"

if $STORE_CREDENTIALS; then
    if [[ -z "$TOKEN" ]]; then
        echo "--token is required when using --store-credentials."
        exit 1
    fi

    git config --global credential.helper store

    CREDENTIALS_FILE="$HOME/.git-credentials"

    cat > "$CREDENTIALS_FILE" <<EOF
https://${USERNAME}:${TOKEN}@github.com
EOF

    chmod 600 "$CREDENTIALS_FILE"
fi

echo ""
echo "==> Summary"

echo ""
echo "Git user:       $USERNAME"
echo "Git email:      $EMAIL"
echo "Default branch: $DEFAULT_BRANCH"

if $STORE_CREDENTIALS; then
    echo "Credential helper:  store"
    echo "Credentials file:   $HOME/.git-credentials"
else
    echo "Credential helper:  unchanged"
fi

echo ""
echo "Bootstrap completed successfully."
