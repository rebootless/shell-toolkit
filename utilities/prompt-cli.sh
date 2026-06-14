#!/bin/bash

# prompt-cli - send a prompt to the Google Gemini API and render the markdown
# response directly in the terminal.

# On first run: self-installs to ~/.local/bin, installs missing
# dependencies (python3, jq, curl) via apt-get, and asks for a Gemini
# API key (stored in ~/.config/prompt-cli/keys.env, chmod 600).

# Usage: ask [--model NAME] <prompt text>
#        ask --setup        (enter the API key, only if not set yet)
#        ask --reset        (clear the stored API key and enter a new one)
#        ask --uninstall    (remove the script and stored config)
#        ask --help         (show usage)
#
# Note: the command name `prompt` is already used by oh-my-bash, so this tool
# is exposed as `ask`.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/prompt-cli"
ASK_PATH="$INSTALL_DIR/ask"
CONFIG_DIR="$HOME/.config/prompt-cli"
KEYS_FILE="$CONFIG_DIR/keys.env"
GEMINI_KEY_URL="https://aistudio.google.com/app/apikey"
GEMINI_API_BASE="https://generativelanguage.googleapis.com/v1beta/models"
DEFAULT_MODEL="gemini-2.5-flash"
MARK_START="# >>> prompt-cli >>>"
MARK_END="# <<< prompt-cli <<<"
BASHRC="$HOME/.bashrc"

# colors / box-drawing
ACCENT=$'\033[36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
UNDERLINE=$'\033[4m'
RED=$'\033[0;31m'
RESET=$'\033[0m'

# Automatic dependency installation via apt-get
check_and_install_deps() {
    if ! command -v python3 &>/dev/null || ! command -v jq &>/dev/null || ! command -v curl &>/dev/null; then
        echo "-------------Installing dependencies-------------"

        local sudo_cmd=""
        if [[ $EUID -ne 0 ]]; then
            if command -v sudo &>/dev/null; then
                sudo_cmd="sudo"
                echo "[*] Requesting root privileges to install missing packages..."
            else
                echo "[!] Root privileges required but 'sudo' is not installed. Please run as root." >&2
                exit 1
            fi
        fi

        echo "[*] Updating package lists..."
        $sudo_cmd apt-get update -y

        echo "[*] Installing required dependencies (python3, jq, curl)..."
        $sudo_cmd apt-get install -y python3 jq curl
        echo "[+] Dependencies installed successfully."
        echo "-------------------------------------------------"
    fi
}

repeat_char() {
    local char="$1" count="$2" out
    if (( count <= 0 )); then return 0; fi
    printf -v out '%*s' "$count" ''
    printf '%s' "${out// /$char}"
}

ensure_installed() {
    local self_path
    self_path="$(readlink -f "$0" 2>/dev/null || echo "$0")"

    if [[ "$self_path" == "$INSTALL_PATH" ]]; then
        ln -sf "$INSTALL_PATH" "$ASK_PATH"
        return 0
    fi

    if [[ ! -f "$self_path" ]]; then
        echo "[i] Running from a non-file source — skipping self-install."
        return 0
    fi

    mkdir -p "$INSTALL_DIR"
    cp "$self_path" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    ln -sf "$INSTALL_PATH" "$ASK_PATH"
    echo "[+] Installed to $INSTALL_PATH"
    echo "[+] Created command alias $ASK_PATH -> $INSTALL_PATH"

    # Idempotent PATH block: skip if markers already present
    if grep -qF "$MARK_START" "$BASHRC" 2>/dev/null; then
        echo "[i] PATH already configured in $BASHRC, skipping."
        return 0
    fi

    {
        echo ""
        echo "$MARK_START"
        echo "export PATH=\"\$PATH:$INSTALL_DIR\""
        echo "$MARK_END"
    } >> "$BASHRC"
    echo "[i] Added $INSTALL_DIR to PATH in $BASHRC"
    echo "[i] Run 'source $BASHRC' or open a new terminal to use the 'ask' command"
}

run_setup() {
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"

    echo "--------------Gemini (Google) setup--------------"
    echo "[i] Free tier available, no billing required."
    echo "[i] Get an API key here: $GEMINI_KEY_URL"
    read -rsp "[>] Enter Gemini API key: " key
    echo

    if [[ -z "$key" ]]; then
        echo "[!] Empty key, aborting setup" >&2
        exit 1
    fi

    printf 'GEMINI_API_KEY=%s\n' "$key" > "$KEYS_FILE"
    chmod 600 "$KEYS_FILE"
    echo "[+] Setup complete. Key stored in $KEYS_FILE"
    echo "-------------------------------------------------"
}

run_reset() {
    if [[ -f "$KEYS_FILE" ]]; then
        read -rp "[?] Clear the stored API key and enter a new one? [y/N]: " confirm
        case "${confirm,,}" in
            y|yes)
                rm -f "$KEYS_FILE"
                echo "[+] Stored key cleared."
                ;;
            *)
                echo "[i] Cancelled"
                return 0
                ;;
        esac
    fi
    run_setup
}

run_uninstall() {
    if [[ ! -e "$INSTALL_PATH" && ! -d "$CONFIG_DIR" ]]; then
        echo "[i] Nothing to remove: $INSTALL_PATH and $CONFIG_DIR not found."
        return 0
    fi

    echo "${RED}${BOLD}╔═════════════════════ WARNING ═════════════════════╗${RESET}"
    echo "${RED}This will permanently delete:${RESET}"
    echo "  - $INSTALL_PATH"
    echo "  - $ASK_PATH"
    echo "  - $CONFIG_DIR (including your stored API key)"
    echo "${RED}${BOLD}╚═══════════════════════════════════════════════════╝${RESET}"

    read -rp "[?] Type 'yes' to confirm removal: " confirm
    case "$confirm" in
        yes)
            rm -f "$INSTALL_PATH"
            rm -f "$ASK_PATH"
            rm -rf "$CONFIG_DIR"
            if grep -qF "$MARK_START" "$BASHRC" 2>/dev/null; then
                sed -i "/${MARK_START}/,/${MARK_END}/d" "$BASHRC"
                echo "[+] Removed PATH block from $BASHRC"
            fi
            echo "[+] Removed $INSTALL_PATH, $ASK_PATH and $CONFIG_DIR"
            echo "[i] You may also remove the PATH entry added to your shell rc file"
            ;;
        *)
            echo "[i] Cancelled"
            ;;
    esac
}

# Compute end - start (both in $EPOCHREALTIME "seconds.microseconds" format)
# as a "N.N" seconds string, using only bash builtins.
elapsed_seconds() {
    local start="$1" end="$2"
    local s_sec="${start%%.*}" s_us="${start#*.}"
    local e_sec="${end%%.*}" e_us="${end#*.}"
    local total_us=$(( (10#$e_sec - 10#$s_sec) * 1000000 + (10#$e_us - 10#$s_us) ))
    (( total_us < 0 )) && total_us=0
    printf '%d.%01d' $(( total_us / 1000000 )) $(( (total_us / 100000) % 10 ))
}

# Sends $1 as a prompt to model $2, polls a spinner while curl runs in the
# background, and sets:
#   REPLY        - raw response body (JSON, or empty on connection failure)
#   REPLY_STATUS - curl exit status
fetch_gemini() {
    local prompt="$1" model="$2"
    local body tmpfile pid status=0 spin i=0

    body=$(jq -n --arg p "$prompt" '{contents:[{parts:[{text:$p}]}]}')
    tmpfile=$(mktemp)
    spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    curl -sS --max-time 120 \
        "${GEMINI_API_BASE}/${model}:generateContent?key=${GEMINI_API_KEY}" \
        -H "content-type: application/json" \
        -d "$body" -o "$tmpfile" &
    pid=$!

    trap 'kill "$pid" 2>/dev/null; rm -f "$tmpfile"; printf "\r\033[2K"; echo "[!] Cancelled." >&2; exit 130' INT TERM

    printf "%s[*]%s Asking %s%s%s%s... " "$DIM" "$RESET" "$BOLD" "$ACCENT" "$model" "$RESET"
    while kill -0 "$pid" 2>/dev/null; do
        printf "%s" "${spin:i++%${#spin}:1}"
        sleep 0.08
        printf "\b"
    done
    wait "$pid" || status=$?
    trap - INT TERM
    printf "\r\033[2K"

    REPLY=$(cat "$tmpfile")
    REPLY_STATUS=$status
    rm -f "$tmpfile"
}

render_markdown() {
    local width="${1:-76}"

    # Keep the renderer in a variable so stdin stays free for the markdown pipe.
    local PY_SCRIPT=$(cat <<'PY'
import os
import re
import sys
from typing import List

WIDTH = max(50, int(os.environ.get("MD_WIDTH", "76")))
ACCENT = "\033[36m"
BOLD = "\033[1m"
ITALIC = "\033[3m"
DIM = "\033[2m"
UNDERLINE = "\033[4m"
RESET = "\033[0m"

ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
CONTROL_RE = re.compile(r"[\x00-\x08\x0b-\x1f\x7f]")


def style(text: str, *codes: str) -> str:
    return "".join(codes) + text + RESET


def strip_control(s: str) -> str:
    return CONTROL_RE.sub("", s)


def strip_ansi(s: str) -> str:
    return ANSI_RE.sub("", s)


def vislen(s: str) -> int:
    return len(strip_ansi(s))


def truncate_ansi(s: str, max_width: int) -> str:
    """Truncate an ANSI-styled string to at most max_width visible columns,
    appending an ellipsis. ANSI escape sequences don't count toward width."""
    if max_width <= 0:
        return ""
    if vislen(s) <= max_width:
        return s
    if max_width == 1:
        return "…"

    out = []
    visible = 0
    limit = max_width - 1
    i = 0
    while i < len(s):
        m = ANSI_RE.match(s, i)
        if m:
            out.append(m.group(0))
            i = m.end()
            continue
        if visible >= limit:
            break
        out.append(s[i])
        visible += 1
        i += 1
    out.append(RESET)
    out.append("…")
    return "".join(out)


def protect_escapes(text: str):
    stash = {}
    i = 0

    def repl(m):
        nonlocal i
        key = f"\x00ESC{i}\x00"
        stash[key] = m.group(1)
        i += 1
        return key

    text = re.sub(r"\\([\\`*_{}\[\]()#+\-.!>|~])", repl, text)
    return text, stash


def restore_escapes(text: str, stash):
    for k, v in stash.items():
        text = text.replace(k, v)
    return text


def inline_format(text: str) -> str:
    text = strip_control(text)
    text, stash = protect_escapes(text)

    # Images
    text = re.sub(
        r'!\[([^\]]*)\]\(([^)\s]+)(?:\s+"([^"]+)")?\)',
        lambda m: style(f"🖼  {m.group(1)} ({m.group(2)})", DIM),
        text,
    )

    # Autolinks
    text = re.sub(r'<(https?://[^>]+)>', lambda m: style(m.group(1), UNDERLINE), text)

    # Inline code placeholders
    code_stash = {}
    ci = 0

    def code_repl(m):
        nonlocal ci
        key = f"\x01CODE{ci}\x01"
        code_stash[key] = style(m.group(1), ACCENT)
        ci += 1
        return key

    text = re.sub(r'`([^`]+)`', code_repl, text)

    # Links
    def link_repl(m):
        label = inline_format(m.group(1)) if any(x in m.group(1) for x in "*`_~[") else m.group(1)
        return f"{style(label, UNDERLINE)} {style(f'({m.group(2)})', DIM)}"

    text = re.sub(r'\[([^\]]+)\]\(([^)\s]+)(?:\s+"([^"]+)")?\)', link_repl, text)

    # Strong / Emphasis / Strike
    text = re.sub(r'(\*\*\*|___)(.+?)\1', lambda m: style(m.group(2), BOLD, ITALIC), text)
    text = re.sub(r'(\*\*|__)(.+?)\1', lambda m: style(m.group(2), BOLD), text)
    text = re.sub(r'~~(.+?)~~', lambda m: style(m.group(1), DIM), text)
    text = re.sub(r'(?<!\w)\*(?!\s)(.+?)(?<!\s)\*(?!\w)', lambda m: style(m.group(1), ITALIC), text)
    text = re.sub(r'(?<!\w)_(?!\s)(.+?)(?<!\s)_(?!\w)', lambda m: style(m.group(1), ITALIC), text)

    for k, v in code_stash.items():
        text = text.replace(k, v)

    return restore_escapes(text, stash)


def wrap_ansi(text: str, width: int, indent: str = "", subsequent_indent: str | None = None) -> List[str]:
    if subsequent_indent is None:
        subsequent_indent = indent
    if width <= 1:
        return [text]

    raw_tokens = re.split(r'(\s+)', text)
    lines = []
    current = indent
    current_len = vislen(indent)
    limit = max(10, width)

    for tok in raw_tokens:
        if tok == "":
            continue
        if tok.isspace():
            if current.strip():
                current += tok
                current_len += len(tok)
            continue
        tok_len = vislen(tok)
        if current_len + tok_len > limit and current.strip():
            lines.append(current.rstrip())
            current = subsequent_indent + tok
            current_len = vislen(subsequent_indent) + tok_len
        else:
            current += tok
            current_len += tok_len
    if current.strip() or not lines:
        lines.append(current.rstrip())
    return lines


def is_table_candidate(line: str) -> bool:
    stripped = line.strip()
    return stripped.count("|") >= 2 and not stripped.startswith("```")


def split_table_row(line: str):
    stripped = line.strip()
    if stripped.startswith("|"):
        stripped = stripped[1:]
    if stripped.endswith("|"):
        stripped = stripped[:-1]
    return [cell.strip() for cell in stripped.split("|")]


def parse_alignment(cell: str) -> str:
    cell = cell.strip().replace(" ", "")
    if cell.startswith(":") and cell.endswith(":"):
        return "center"
    if cell.startswith(":"):
        return "left"
    if cell.endswith(":"):
        return "right"
    return "left"


def is_separator_row(cells):
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", c.replace(" ", "")) for c in cells)


def render_table(rows: List[str]):
    if len(rows) < 2:
        for r in rows:
            print(inline_format(r))
        return

    parsed = [split_table_row(r) for r in rows]
    sep_idx = None
    for i, cells in enumerate(parsed):
        if is_separator_row(cells):
            sep_idx = i
            break

    if sep_idx is None:
        for r in rows:
            print(inline_format(r))
        return

    header = parsed[0]
    align_row = parsed[sep_idx]
    body = [r for i, r in enumerate(parsed) if i not in (0, sep_idx)]
    cols = max(len(header), max((len(r) for r in body), default=0), len(align_row))
    widths = [0] * cols

    all_rows = [header] + body
    for row in all_rows:
        for i in range(cols):
            cell = inline_format(row[i]) if i < len(row) else ""
            widths[i] = max(widths[i], vislen(cell))

    aligns = [parse_alignment(align_row[i]) if i < len(align_row) else "left" for i in range(cols)]

    # If the natural table width overflows the terminal, shrink the widest
    # columns one column-width at a time until it fits (down to a minimum
    # width); overflowing cells get truncated with an ellipsis when rendered.
    overhead = 3 * cols + 1
    avail = max(20, WIDTH)
    min_w = 3
    total_width = sum(widths) + overhead
    if total_width > avail:
        excess = total_width - avail
        while excess > 0 and any(w > min_w for w in widths):
            idx = max(range(cols), key=lambda i: widths[i])
            widths[idx] -= 1
            excess -= 1
        total_width = sum(widths) + overhead

    def pad(cell: str, idx: int) -> str:
        target = widths[idx]
        cell = truncate_ansi(cell, target)
        vis = vislen(cell)
        if vis >= target:
            return cell
        gap = target - vis
        if aligns[idx] == "right":
            return " " * gap + cell
        if aligns[idx] == "center":
            left = gap // 2
            right = gap - left
            return " " * left + cell + " " * right
        return cell + " " * gap

    def render_row(row, header_row=False):
        cells = []
        for i in range(cols):
            cell = inline_format(row[i]) if i < len(row) else ""
            if header_row:
                cell = style(cell, BOLD)
            cells.append(pad(cell, i))
        print(style("│", ACCENT) + " " + f" {style('│', ACCENT)} ".join(cells) + " " + style("│", ACCENT))

    print(style("┌" + "─" * (total_width - 2) + "┐", ACCENT))
    render_row(header, header_row=True)
    print(style("├" + "─" * (total_width - 2) + "┤", ACCENT))
    for row in body:
        render_row(row)
    print(style("└" + "─" * (total_width - 2) + "┘", ACCENT))


def flush_paragraph(buf):
    if not buf:
        return
    text = " ".join(buf).strip()
    if not text:
        buf.clear()
        return
    for line in wrap_ansi(inline_format(text), WIDTH):
        print(line)
    buf.clear()


in_code = False
code_lang = ""
table_buf = []
para_buf = []


def flush_table():
    global table_buf
    if table_buf:
        render_table(table_buf)
        table_buf = []


def flush_para():
    global para_buf
    if para_buf:
        flush_paragraph(para_buf)
        para_buf = []


def flush_all():
    flush_table()
    flush_para()


for raw in sys.stdin:
    line = raw.rstrip("\n").rstrip("\r")

    if line.startswith("```"):
        flush_all()
        fence_lang = line[3:].strip()
        if not in_code:
            in_code = True
            code_lang = fence_lang
            label = f" {code_lang}" if code_lang else ""
            print(style(f"╭─ code{label}", ACCENT))
        else:
            in_code = False
            print(style("╰─", ACCENT))
        continue

    if in_code:
        if line.strip():
            print(style("  " + strip_control(line), DIM))
        else:
            print("")
        continue

    if not line.strip():
        flush_all()
        print("")
        continue

    if is_table_candidate(line):
        flush_para()
        table_buf.append(line)
        continue
    elif table_buf:
        flush_table()

    if re.match(r'^(?:-{3,}|\*{3,}|_{3,})\s*$', line):
        flush_para()
        print(style("─" * min(WIDTH, 72), DIM))
        continue

    # Headings
    m = re.match(r'^(#{1,6})\s+(.*)$', line)
    if m:
        flush_all()
        level = len(m.group(1))
        title = inline_format(m.group(2).strip())
        plain = strip_ansi(title)
        if level == 1:
            print(style(title, ACCENT, BOLD, UNDERLINE))
            print(style("═" * min(WIDTH, max(24, len(plain))), ACCENT))
        elif level == 2:
            print(style(title, ACCENT, BOLD))
            print(style("─" * min(WIDTH, max(20, len(plain))), ACCENT))
        else:
            indent = "  " * (level - 3)
            print(f"{indent}{style(title, ACCENT, BOLD)}")
        continue

    # Blockquotes
    m = re.match(r'^(\s*(?:>\s*)+)(.*)$', line)
    if m:
        flush_para()
        prefix = m.group(1)
        depth = prefix.count('>')
        body = m.group(2).strip()
        quote = "  " * (depth - 1)
        marker = style("▌", ACCENT)
        rendered = inline_format(body)
        for wrapped in wrap_ansi(rendered, WIDTH - len(quote) - 2, indent="", subsequent_indent=""):
            print(f"{quote}{marker} {wrapped}")
        continue

    # Task list
    m = re.match(r'^(\s*)([-*+])\s+\[( |x|X)\]\s+(.*)$', line)
    if m:
        flush_para()
        indent, _, checked, body = m.groups()
        mark = "☑" if checked.lower() == "x" else "☐"
        print(f"{indent}{style(mark, ACCENT)} {inline_format(body)}")
        continue

    # Bullets
    m = re.match(r'^(\s*)([-*+])\s+(.*)$', line)
    if m:
        flush_para()
        indent, _, body = m.groups()
        rendered = inline_format(body)
        for i, wrapped in enumerate(wrap_ansi(rendered, WIDTH - len(indent) - 2, indent="", subsequent_indent="  ")):
            bullet = style("•", ACCENT) if i == 0 else " "
            print(f"{indent}{bullet} {wrapped}" if i == 0 else f"{indent}  {wrapped}")
        continue

    # Numbered lists
    m = re.match(r'^(\s*)(\d+)[.)]\s+(.*)$', line)
    if m:
        flush_para()
        indent, num, body = m.groups()
        rendered = inline_format(body)
        prefix = f"{indent}{style(num + '.', ACCENT)} "
        subsequent = " " * vislen(prefix)
        for i, wrapped in enumerate(wrap_ansi(rendered, WIDTH - vislen(prefix), indent="", subsequent_indent=subsequent)):
            if i == 0:
                print(prefix + wrapped)
            else:
                print(wrapped)
        continue

    # Definition lines: "Term: definition text" (short label, non-empty body)
    m = re.match(r'^(\s*)([^\s:][^:]{0,48})\s*:\s+(\S.*)$', line)
    if m:
        flush_para()
        term, definition = m.group(2), m.group(3)
        print(style(term, BOLD))
        for wrapped in wrap_ansi(inline_format(definition), WIDTH - 2, indent="  ", subsequent_indent="  "):
            print(f"  {style('→', ACCENT)} {wrapped.strip()}")
        continue

    para_buf.append(line)

flush_all()
PY
)
    # Pass the renderer via -c so stdin stays free for the piped markdown.
    MD_WIDTH="$width" python3 -c "$PY_SCRIPT"
}

box_top() {
    local title="$1" width="$2"
    local label=" ${title} "
    local inner=$(( width - ${#label} - 3 ))
    (( inner < 1 )) && inner=1
    printf '%s╭─%s%s%s%s╮%s\n' "$ACCENT" "$RESET$BOLD" "$label" "$RESET$ACCENT" "$(repeat_char '─' "$inner")" "$RESET"
}

box_bottom() {
    local info="$1" width="$2"
    local label=" ${info} "
    local inner=$(( width - ${#label} - 3 ))
    (( inner < 1 )) && inner=1
    printf '%s╰─%s%s%s%s╯%s\n' "$ACCENT" "$RESET$DIM" "$label" "$RESET$ACCENT" "$(repeat_char '─' "$inner")" "$RESET"
}

print_help() {
    cat <<EOF
prompt-cli - send a prompt to Google Gemini from the command line

Note: `prompt` is already used by oh-my-bash; use `ask` instead.

Usage:
  ask [--model NAME] <text>      Send <text> as a prompt and print the response
  ask --setup                    Enter the API key (only if not set yet)
  ask --reset                    Clear the stored API key and enter a new one
  ask --uninstall                Remove the script ($INSTALL_PATH), alias ($ASK_PATH) and config ($CONFIG_DIR)
  ask --help                     Show this help

Options:
  --model NAME   Override the model for this request (default: $DEFAULT_MODEL)
                 Examples: gemini-2.5-flash, gemini-2.5-pro, gemini-2.5-flash-lite
                 Availability depends on your account/region.

API key storage: $KEYS_FILE

Note: token counts shown after each response come from the API response
itself. Rate limits and quotas are NOT part of that response - check and
manage them in Google AI Studio / Google Cloud Console.
EOF
}

main() {
    case "${1:-}" in
        --help|-h)
            print_help
            exit 0
            ;;
        --uninstall)
            run_uninstall
            exit 0
            ;;
    esac

    ensure_installed

    case "${1:-}" in
        --setup)
            if [[ -f "$KEYS_FILE" ]]; then
                echo "[i] A key is already configured. Use 'ask --reset' to replace it."
                exit 0
            fi
            run_setup
            exit 0
            ;;
        --reset)
            run_reset
            exit 0
            ;;
    esac

    if [[ $# -eq 0 ]]; then
        echo "[!] Usage: ask [--model NAME] <text>" >&2
        echo "[i] Run 'ask --help' for details." >&2
        exit 1
    fi

    if [[ ! -f "$KEYS_FILE" ]]; then
        echo "[i] No API key configured yet, running first-time setup..."
        run_setup
    fi

    check_and_install_deps

    # shellcheck disable=SC1090
    source "$KEYS_FILE"

    # Parse --model NAME / --model=NAME anywhere in the arguments;
    # everything else is joined back together as the prompt text.
    local model="$DEFAULT_MODEL"
    local -a prompt_words=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --model)
                if [[ $# -lt 2 ]]; then
                    echo "[!] --model requires a value" >&2
                    exit 1
                fi
                model="$2"
                shift 2
                ;;
            --model=*)
                model="${1#--model=}"
                shift
                ;;
            *)
                prompt_words+=("$1")
                shift
                ;;
        esac
    done

    if [[ ${#prompt_words[@]} -eq 0 ]]; then
        echo "[!] Usage: ask [--model NAME] <text>" >&2
        exit 1
    fi

    local prompt_text="${prompt_words[*]}"
    if [[ -z "${prompt_text// /}" ]]; then
        echo "[!] Prompt text is empty." >&2
        exit 1
    fi

    local start end resp status
    start=$EPOCHREALTIME
    fetch_gemini "$prompt_text" "$model"
    end=$EPOCHREALTIME
    resp="$REPLY"
    status="$REPLY_STATUS"

    if [[ "$status" -ne 0 ]]; then
        echo "[!] Connection to Gemini API failed (curl exit code $status)." >&2
        exit 1
    fi

    if [[ -z "$resp" ]]; then
        echo "[!] Empty response from Gemini API." >&2
        exit 1
    fi

    local err_msg
    err_msg=$(jq -r '.error.message // empty' <<< "$resp" 2>/dev/null || true)
    if [[ -n "$err_msg" ]]; then
        echo "[!] Gemini error: $err_msg" >&2
        echo "[i] Run 'ask --reset' if your key may be invalid, or check the model name with --model." >&2
        exit 1
    fi

    local block_reason
    block_reason=$(jq -r '.promptFeedback.blockReason // empty' <<< "$resp" 2>/dev/null || true)
    if [[ -n "$block_reason" ]]; then
        echo "[!] Gemini blocked the prompt (reason: $block_reason)." >&2
        exit 1
    fi

    local text
    text=$(jq -r '[.candidates[0]?.content.parts[]? | select(.thought != true) | (.text // "")] | join("")' <<< "$resp" 2>/dev/null || true)

    if [[ -z "$text" ]]; then
        local finish
        finish=$(jq -r '.candidates[0].finishReason // "unknown"' <<< "$resp" 2>/dev/null || echo "unknown")
        echo "[!] No text in response (finishReason: $finish)." >&2
        exit 1
    fi

    local width
    width=$(tput cols 2>/dev/null || echo 80)
    (( width > 120 )) && width=120
    (( width < 60 )) && width=60

    box_top "Gemini · ${model}" "$width"
    printf '%s\n' "$text" | render_markdown $((width - 4)) | sed "s/^/${ACCENT}│${RESET} /"

    local pt ct tt th elapsed info
    pt=$(jq -r '.usageMetadata.promptTokenCount // "?"' <<< "$resp")
    ct=$(jq -r '.usageMetadata.candidatesTokenCount // "?"' <<< "$resp")
    tt=$(jq -r '.usageMetadata.totalTokenCount // "?"' <<< "$resp")
    th=$(jq -r '.usageMetadata.thoughtsTokenCount // 0' <<< "$resp")
    elapsed=$(elapsed_seconds "$start" "$end")

    info="${pt} in · ${ct} out"
    if [[ "$th" != "0" ]]; then
        info+=" · ${th} think"
    fi
    info+=" · ${tt} total · ${elapsed}s"

    box_bottom "$info" "$width"
}

main "$@"
