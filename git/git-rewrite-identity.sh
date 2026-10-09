#!/bin/bash

# ---DOC-START---
# summary: Rewrite author/committer name and email across all commits in a Git repository.
# description: |
#   Uses git-filter-repo to replace a given author/committer name and/or
#   email with new values across the entire commit history of a repository.
#   Useful when commits were made under an OS-level username instead of the
#   intended account identity. Rewrites all refs; commit hashes change.
#   The 'origin' remote is removed by git-filter-repo as a safety measure
#   and is automatically re-added at the end if it was present.
# sudo: false
# interactive: true
# idempotent: false
# ---DOC-END---

set -euo pipefail

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

REPO="."
OLD_NAME=""
NEW_NAME=""
OLD_EMAIL=""
NEW_EMAIL=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Rewrite Git commit author/committer information across the full history.

Show all unique author identities (name + email):
git log --all --format='%an <%ae>' | sort -u

Options:
  -r, --repo PATH          Repository path (default: current directory)
      --old-name NAME      Author/committer name to replace
      --new-name NAME      Replacement name
      --old-email EMAIL    Author/committer email to replace
      --new-email EMAIL    Replacement email
  -h, --help               Show this help message

Examples:
  $(basename "$0") --old-name "OLD" --new-name "NEW"

  $(basename "$0") --old-email "old@example.com" --new-email "new@example.com"

  $(basename "$0") \\
      --repo /path/to/repo \\
      --old-name "OLD" --new-name "NEW" \\
      --old-email "old@example.com" --new-email "new@example.com"
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--repo)
            REPO="$2"
            shift 2
            ;;
        --old-name)
            OLD_NAME="$2"
            shift 2
            ;;
        --new-name)
            NEW_NAME="$2"
            shift 2
            ;;
        --old-email)
            OLD_EMAIL="$2"
            shift 2
            ;;
        --new-email)
            NEW_EMAIL="$2"
            shift 2
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

if command -v git-filter-repo >/dev/null 2>&1; then
    echo "git-filter-repo already installed, skipping..."
else
    echo "git-filter-repo not found."
    echo "Install it, e.g.:"
    echo "  pipx install git-filter-repo"
    exit 1
fi

if [[ -z "$OLD_NAME" && -z "$OLD_EMAIL" ]]; then
    echo "Specify at least --old-name (with --new-name) or --old-email (with --new-email)."
    usage
    exit 1
fi

if [[ ( -n "$OLD_NAME" && -z "$NEW_NAME" ) || ( -z "$OLD_NAME" && -n "$NEW_NAME" ) ]]; then
    echo "--old-name and --new-name must be used together."
    exit 1
fi

if [[ ( -n "$OLD_EMAIL" && -z "$NEW_EMAIL" ) || ( -z "$OLD_EMAIL" && -n "$NEW_EMAIL" ) ]]; then
    echo "--old-email and --new-email must be used together."
    exit 1
fi

if [[ ! -d "$REPO/.git" ]]; then
    echo "'$REPO' is not a Git repository."
    exit 1
fi

cd "$REPO"
REPO="$(pwd)"
echo "Repository OK: $REPO"

ORIGIN_URL=""
if git remote get-url origin >/dev/null 2>&1; then
    ORIGIN_URL="$(git remote get-url origin)"
    echo "origin: $ORIGIN_URL"
else
    echo "No 'origin' remote configured."
fi

echo ""
[[ -n "$OLD_NAME" ]]  && echo "Name:  '$OLD_NAME'  ->  '$NEW_NAME'"
[[ -n "$OLD_EMAIL" ]] && echo "Email: '$OLD_EMAIL'  ->  '$NEW_EMAIL'"

echo ""
echo -e "${RED}This rewrites ALL commits in $REPO"
echo -e "${RED}Every commit hash will change.${NC}"
echo -e "${RED}Anyone else with a clone must re-clone or${NC}"
echo -e "${RED}hard-reset onto the new history.${NC}"
echo -e "${RED}THIS ACTION IS IRREVERSIBLE without a backup.${NC}"

read -rp "Proceed with rewriting history? [y/N]: " PROCEED
if [[ ! "${PROCEED,,}" =~ ^y ]]; then
    echo "Aborted."
    exit 0
fi

read -rp "Are you sure? This cannot be undone. Type 'yes' to confirm: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Confirmation not received — aborting."
    exit 0
fi

export OLD_NAME NEW_NAME OLD_EMAIL NEW_EMAIL

git filter-repo --force --commit-callback '
if os.environ.get("OLD_NAME") and commit.author_name == os.environ["OLD_NAME"].encode():
    commit.author_name = os.environ["NEW_NAME"].encode()

if os.environ.get("OLD_NAME") and commit.committer_name == os.environ["OLD_NAME"].encode():
    commit.committer_name = os.environ["NEW_NAME"].encode()

if os.environ.get("OLD_EMAIL") and commit.author_email == os.environ["OLD_EMAIL"].encode():
    commit.author_email = os.environ["NEW_EMAIL"].encode()

if os.environ.get("OLD_EMAIL") and commit.committer_email == os.environ["OLD_EMAIL"].encode():
    commit.committer_email = os.environ["NEW_EMAIL"].encode()
'

echo "History rewritten."

if [[ -n "$ORIGIN_URL" ]]; then
    if ! git remote get-url origin >/dev/null 2>&1; then
        git remote add origin "$ORIGIN_URL"
        echo "Remote 'origin' re-added: $ORIGIN_URL"
    fi
fi

echo ""
echo "==> Summary"

echo ""
echo "Rewrite complete."

echo ""
echo "Repo: $REPO"
[[ -n "$OLD_NAME" ]]  && echo "Name:  '$OLD_NAME' -> '$NEW_NAME'"
[[ -n "$OLD_EMAIL" ]] && echo "Email: '$OLD_EMAIL' -> '$NEW_EMAIL'"

echo ""
echo "Review before pushing:"
echo "  git log --pretty=full | less"

echo ""
echo "Push rewritten history:"
echo "  git push --force --all"
echo "  git push --force --tags"
