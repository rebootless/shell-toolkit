#!/usr/bin/env python3
"""
generate-docs.py

Scans every *.sh file in the repository for a documentation metadata block:

    #!/bin/bash
    # ---DOC-START---
    # summary: ...
    # description: |
    #   ...
    # sudo: true|false
    # interactive: true|false
    # idempotent: true|false|mostly
    # dependencies: path/to/other-script.sh, path/to/another.sh|none
    # ---DOC-END---

...and renders a single static HTML page (docs/index.html) with a summary
table and a detailed, per-directory breakdown of every script -- including,
for each script, a dependency tree built from its `dependencies` field.

Only index.html is generated. The page skeleton lives next to it in docs/ and is
edited by hand: template.html (markup with {{PLACEHOLDERS}}), style.css, app.js.

Usage:
    ./generate-docs.py                 # scan repo root, write docs/index.html
    ./generate-docs.py --strict        # exit non-zero if any *.sh has no block
    ./generate-docs.py --root DIR      # scan a different repo root
    ./generate-docs.py --out FILE      # write to a different output path

No third-party dependencies -- standard library only, so it runs the same way
locally and in CI (see .github/workflows).
"""

from __future__ import annotations

import argparse
import datetime
import html
import os
import re
import sys
from dataclasses import dataclass, field

DOC_START = "# ---DOC-START---"
DOC_END = "# ---DOC-END---"

# Directories that are never part of the documented toolkit (i.e. never scanned for scripts).
EXCLUDED_DIRS = {".git", "docs", "node_modules", ".github"}

# Directories/files excluded from the *repository structure tree* (junk only --
# unlike EXCLUDED_DIRS above, the tree does want to show docs/ and .github/).
TREE_EXCLUDE = {".git", "__pycache__", "node_modules", ".DS_Store"}

TOP_KEY_RE = re.compile(r"^# ([a-zA-Z_]+): ?(.*)$")


def slugify(text: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]+", "-", text).strip("-").lower()


def dir_anchor(directory: str) -> str:
    slug = slugify(directory)
    return f"dir-{slug}" if slug else "dir-root"


def permalink_html(anchor: str) -> str:
    """A small '#' link that only appears on hover, for grabbing a direct URL to a heading."""
    return f'<a class="permalink" href="#{anchor}" aria-label="Link to this section">#</a>'


@dataclass
class ScriptDoc:
    relpath: str  # e.g. "server/deploy-nginx.sh"
    summary: str = ""
    description: str = ""
    sudo: bool = False
    interactive: bool = False
    idempotent: str = "false"  # "true" | "false" | "mostly"
    dependencies: list[str] = field(default_factory=list)  # relpaths of other repo scripts

    @property
    def directory(self) -> str:
        d = os.path.dirname(self.relpath)
        return d if d else "."

    @property
    def filename(self) -> str:
        return os.path.basename(self.relpath)

    @property
    def anchor(self) -> str:
        return "script-" + re.sub(r"[^a-zA-Z0-9]+", "-", self.relpath).strip("-").lower()


def find_scripts(root: str) -> list[str]:
    found = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDED_DIRS and not d.startswith(".")]
        for fn in filenames:
            if fn.endswith(".sh"):
                found.append(os.path.relpath(os.path.join(dirpath, fn), root))
    return sorted(found)


def parse_bool(value: str, default: bool = False) -> bool:
    return value.strip().lower() == "true"


def parse_doc_block(path: str, relpath: str) -> ScriptDoc | None:
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        text = f.read()

    start = text.find(DOC_START)
    end = text.find(DOC_END)
    if start == -1 or end == -1 or end < start:
        return None

    block = text[start + len(DOC_START):end].split("\n")

    doc = ScriptDoc(relpath=relpath)
    in_description = False
    desc_lines: list[str] = []

    for raw_line in block:
        top_match = TOP_KEY_RE.match(raw_line)
        is_top_level = top_match is not None and not raw_line.startswith("#   ")

        if is_top_level:
            if in_description:
                doc.description = "\n".join(desc_lines).strip("\n")
                in_description = False
                desc_lines = []

            key, value = top_match.group(1), top_match.group(2)
            value = value.strip()

            if key == "summary":
                doc.summary = value
            elif key == "description":
                if value == "|":
                    in_description = True
                    desc_lines = []
                else:
                    doc.description = value
            elif key == "sudo":
                doc.sudo = parse_bool(value)
            elif key == "interactive":
                doc.interactive = parse_bool(value)
            elif key == "idempotent":
                doc.idempotent = value.lower() if value.lower() in ("true", "false", "mostly") else "false"
            elif key == "dependencies":
                if value.strip().lower() in ("", "none"):
                    doc.dependencies = []
                else:
                    doc.dependencies = [dep.strip() for dep in value.split(",") if dep.strip()]
            continue

        if in_description:
            if raw_line == "#":
                desc_lines.append("")
            elif raw_line.startswith("#   "):
                desc_lines.append(raw_line[4:])
            elif raw_line.startswith("# "):
                desc_lines.append(raw_line[2:])
            # blank lines between markers are ignored otherwise

    if in_description:
        doc.description = "\n".join(desc_lines).strip("\n")

    return doc

# Minimal markdown -> HTML (only the subset used in DOC-START/DOC-END blocks:
# paragraphs, "- " bullet lists, "> " blockquotes, **bold**, `code`, [text](url))

def render_inline(text: str) -> str:
    escaped = html.escape(text, quote=False)

    # Protect inline code spans first so bold/link patterns don't reach inside them.
    code_spans: list[str] = []

    def stash_code(m: re.Match) -> str:
        code_spans.append(m.group(1))
        return f"\x00CODE{len(code_spans) - 1}\x00"

    escaped = re.sub(r"`([^`]+)`", stash_code, escaped)
    escaped = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', escaped)
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)

    def restore_code(m: re.Match) -> str:
        idx = int(m.group(1))
        return f"<code>{code_spans[idx]}</code>"

    escaped = re.sub(r"\x00CODE(\d+)\x00", restore_code, escaped)
    return escaped


def render_description(md: str) -> str:
    if not md.strip():
        return ""

    lines = md.split("\n")
    blocks: list[str] = []
    para: list[str] = []
    list_items: list[str] = []
    quote_lines: list[str] = []

    def flush_para():
        if para:
            blocks.append(f"<p>{render_inline(' '.join(para))}</p>")
            para.clear()

    def flush_list():
        if list_items:
            items = "".join(f"<li>{render_inline(it)}</li>" for it in list_items)
            blocks.append(f"<ul>{items}</ul>")
            list_items.clear()

    def flush_quote():
        if quote_lines:
            inner = "<br>".join(render_inline(q) if q else "" for q in quote_lines)
            blocks.append(f"<blockquote>{inner}</blockquote>")
            quote_lines.clear()

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("- "):
            flush_para()
            flush_quote()
            list_items.append(stripped[2:])
        elif stripped.startswith(">"):
            flush_para()
            flush_list()
            quote_lines.append(stripped[1:].strip())
        elif stripped == "":
            flush_para()
            flush_list()
            flush_quote()
        else:
            flush_list()
            flush_quote()
            para.append(stripped)

    flush_para()
    flush_list()
    flush_quote()

    return "\n".join(blocks)

# Repository structure tree (fully discovered from the filesystem)

def _list_dir(path: str) -> tuple[list[str], list[str]]:
    dirs, files = [], []
    for entry in os.listdir(path):
        if entry in TREE_EXCLUDE or entry == ".git":
            continue
        full = os.path.join(path, entry)
        (dirs if os.path.isdir(full) else files).append(entry)
    return sorted(dirs), sorted(files)


# Repo name is fixed rather than derived from the local checkout's folder name
# (which varies -- e.g. a CI runner's workspace dir), so the tree always reads
# "shell-toolkit/" regardless of what the containing directory happens to be called.
REPO_NAME = "shell-toolkit"


def build_tree_text(root: str) -> str:
    lines = [f"{REPO_NAME}/"]

    def recurse(path: str, prefix: str, rel: str):
        dirs, files = _list_dir(path)
        entries = [(d, True) for d in dirs] + [(f, False) for f in files]
        for i, (name, is_dir) in enumerate(entries):
            is_last = i == len(entries) - 1
            connector = "\u2514\u2500\u2500 " if is_last else "\u251c\u2500\u2500 "
            display = name + "/" if is_dir else name
            child_rel = f"{rel}/{name}" if rel else name
            line = prefix + connector + display
            lines.append(line)
            if is_dir:
                extension = "    " if is_last else "\u2502   "
                recurse(os.path.join(path, name), prefix + extension, child_rel)

    recurse(root, "", "")
    return "\n".join(lines)

# Aggregate stats over parsed docs

def compute_stats(docs: list[ScriptDoc]) -> dict:
    total = len(docs)
    sudo_count = sum(1 for d in docs if d.sudo)
    interactive_count = sum(1 for d in docs if d.interactive)
    idempotent_counts = {"true": 0, "mostly": 0, "false": 0}
    for d in docs:
        idempotent_counts[d.idempotent] = idempotent_counts.get(d.idempotent, 0) + 1
    by_dir: dict[str, int] = {}
    for d in docs:
        by_dir[d.directory] = by_dir.get(d.directory, 0) + 1
    with_deps_count = sum(1 for d in docs if d.dependencies)
    return {
        "total": total,
        "directories": len(by_dir),
        "by_dir": by_dir,
        "sudo_count": sudo_count,
        "interactive_count": interactive_count,
        "idempotent_counts": idempotent_counts,
        "with_deps_count": with_deps_count,
    }

# Dependency trees (built from each script's `dependencies` field)

def find_missing_dependencies(docs: list[ScriptDoc]) -> dict[str, list[str]]:
    """Map relpath -> list of declared dependencies that don't resolve to a documented script."""
    docs_by_path = {d.relpath: d for d in docs}
    missing: dict[str, list[str]] = {}
    for d in docs:
        bad = [dep for dep in d.dependencies if dep not in docs_by_path]
        if bad:
            missing[d.relpath] = bad
    return missing


def build_reverse_dependencies(docs: list[ScriptDoc]) -> dict[str, list[str]]:
    """Map relpath -> list of scripts that declare it as a dependency ("used by")."""
    docs_by_path = {d.relpath: d for d in docs}
    reverse: dict[str, list[str]] = {}
    for d in docs:
        for dep in d.dependencies:
            if dep in docs_by_path:  # only resolve real, documented targets
                reverse.setdefault(dep, []).append(d.relpath)
    for relpath in reverse:
        reverse[relpath].sort()
    return reverse


def find_circular_dependencies(docs: list[ScriptDoc]) -> list[list[str]]:
    """Find dependency cycles across the whole graph.

    Returns a de-duplicated list of cycles, each expressed as the ordered chain of
    relpaths that make up the loop (first and last entries are the same script).
    """
    docs_by_path = {d.relpath: d for d in docs}
    cycles: list[list[str]] = []
    seen_cycle_sets: set[frozenset[str]] = set()

    def dfs(relpath: str, stack: list[str], on_stack: set[str]):
        if relpath in on_stack:
            start = stack.index(relpath)
            chain = stack[start:] + [relpath]
            key = frozenset(chain[:-1])
            if key not in seen_cycle_sets:
                seen_cycle_sets.add(key)
                cycles.append(chain)
            return
        doc = docs_by_path.get(relpath)
        if doc is None:
            return
        stack.append(relpath)
        on_stack.add(relpath)
        for dep in doc.dependencies:
            if dep in docs_by_path:
                dfs(dep, stack, on_stack)
        stack.pop()
        on_stack.discard(relpath)

    for d in docs:
        dfs(d.relpath, [], set())

    return cycles


def render_dependency_tree(doc: ScriptDoc, docs_by_path: dict[str, ScriptDoc],
                            stack: tuple[str, ...] = ()) -> str:
    """Recursively render this script's dependencies as a nested <ul> tree.

    Handles two edge cases so a bad/typo'd metadata block can't break generation:
    - a dependency path that doesn't match any documented script ("not found")
    - a dependency cycle (A depends on B which depends on A) ("circular reference")
    """
    if not doc.dependencies:
        return ""

    items = []
    for dep in doc.dependencies:
        dep_doc = docs_by_path.get(dep)
        if dep in stack:
            items.append(
                f'<li><code>{html.escape(dep)}</code> '
                f'<span class="dep-flag dep-cycle">circular reference</span></li>'
            )
        elif dep_doc is None:
            items.append(
                f'<li><code>{html.escape(dep)}</code> '
                f'<span class="dep-flag dep-missing">not found</span></li>'
            )
        else:
            child_tree = render_dependency_tree(dep_doc, docs_by_path, stack + (doc.relpath,))
            link = f'<a href="#{dep_doc.anchor}"><code>{html.escape(dep)}</code></a>'
            items.append(f"<li>{link}{child_tree}</li>")

    return "<ul class=\"dep-tree\">" + "".join(items) + "</ul>"


def build_dependency_section(doc: ScriptDoc, docs_by_path: dict[str, ScriptDoc]) -> str:
    if not doc.dependencies:
        return '<div class="dep-section"><strong>Dependencies:</strong> <span class="dep-none">none</span></div>'
    tree = render_dependency_tree(doc, docs_by_path)
    return f'<div class="dep-section"><strong>Dependencies:</strong>{tree}</div>'


def build_used_by_section(doc: ScriptDoc, reverse_deps: dict[str, list[str]],
                           docs_by_path: dict[str, ScriptDoc]) -> str:
    users = reverse_deps.get(doc.relpath)
    if not users:
        return '<div class="dep-section"><strong>Used by:</strong> <span class="dep-none">none</span></div>'
    items = []
    for user in users:
        user_doc = docs_by_path.get(user)
        if user_doc is not None:
            items.append(f'<li><a href="#{user_doc.anchor}"><code>{html.escape(user)}</code></a></li>')
        else:
            items.append(f'<li><code>{html.escape(user)}</code></li>')
    return f'<div class="dep-section"><strong>Used by:</strong><ul class="dep-tree">{"".join(items)}</ul></div>'

# HTML rendering

TEMPLATE_NAME = "template.html"
PLACEHOLDER_RE = re.compile(r"\{\{([A-Z_]+)\}\}")


def render_template(template: str, values: dict[str, str]) -> str:
    """Fill {{NAME}} placeholders in a single pass (inserted content is never re-scanned)."""
    def substitute(m: re.Match) -> str:
        key = m.group(1)
        if key not in values:
            raise KeyError(f"unknown placeholder {{{{{key}}}}} in {TEMPLATE_NAME}")
        return values[key]
    return PLACEHOLDER_RE.sub(substitute, template)


IDEMPOTENT_BADGE = {"true": "\u2705", "false": "\u274c", "mostly": "\u26a0\ufe0f"}
BOOL_BADGE = {True: "\u2705", False: "\u274c"}


IDEMPOTENT_SORT_ORDER = {"true": 2, "mostly": 1, "false": 0}


def build_summary_table(docs: list[ScriptDoc]) -> str:
    rows = []
    for d in docs:
        search_blob = html.escape(f"{d.directory} {d.filename} {d.summary}".lower(), quote=True)
        deps_count = len(d.dependencies)
        rows.append(
            f'<tr data-search="{search_blob}" data-sudo="{1 if d.sudo else 0}" '
            f'data-interactive="{1 if d.interactive else 0}" data-hasdeps="{1 if deps_count else 0}">'
            f'<td class="dir-tag" data-value="{html.escape(d.directory, quote=True)}">{html.escape(d.directory)}</td>'
            f'<td data-value="{html.escape(d.filename, quote=True)}">'
            f'<a href="#{d.anchor}"><code>{html.escape(d.filename)}</code></a></td>'
            f'<td data-value="{html.escape(d.summary.lower(), quote=True)}">{render_inline(d.summary)}</td>'
            f'<td class="badge" data-value="{1 if d.sudo else 0}">{BOOL_BADGE[d.sudo]}</td>'
            f'<td class="badge" data-value="{1 if d.interactive else 0}">{BOOL_BADGE[d.interactive]}</td>'
            f'<td class="badge" data-value="{IDEMPOTENT_SORT_ORDER.get(d.idempotent, 0)}">'
            f'{IDEMPOTENT_BADGE.get(d.idempotent, "\u274c")}</td>'
            f'<td class="deps-count" data-value="{deps_count}">{deps_count if deps_count else "\u2014"}</td>'
            "</tr>"
        )

    headers = [
        ("Directory", "text", True),
        ("Script", "text", True),
        ("Summary", "text", True),
        ("Sudo", "num", True),
        ("Interactive", "num", True),
        ("Idempotent", "num", True),
        ("Deps", "num", True),
    ]
    head_cells = "".join(
        f'<th data-col="{i}" data-type="{col_type}" class="sortable">{label}'
        f'<span class="sort-indicator"></span></th>'
        if sortable else f"<th>{label}</th>"
        for i, (label, col_type, sortable) in enumerate(headers)
    )

    return (
        '<table id="all-scripts-table">\n<thead><tr>' + head_cells + "</tr></thead>\n<tbody>\n"
        + "\n".join(rows) + "\n</tbody>\n</table>"
    )


def build_script_card(d: ScriptDoc, docs_by_path: dict[str, ScriptDoc],
                       reverse_deps: dict[str, list[str]]) -> str:
    desc_html = render_description(d.description)
    deps_html = build_dependency_section(d, docs_by_path)
    used_by_html = build_used_by_section(d, reverse_deps, docs_by_path)
    search_blob = html.escape(f"{d.directory} {d.filename} {d.summary}".lower(), quote=True)
    return f"""<div class="script-card" id="{d.anchor}" data-search="{search_blob}" \
data-sudo="{1 if d.sudo else 0}" data-interactive="{1 if d.interactive else 0}" \
data-hasdeps="{1 if d.dependencies else 0}">
<h3><code>{html.escape(d.relpath)}</code>{permalink_html(d.anchor)}<button type="button" class="copy-btn" \
data-path="{html.escape(d.relpath, quote=True)}" title="Copy path" aria-label="Copy path">&#10697;</button></h3>
<div class="meta-row">
<span class="badge">Sudo: {BOOL_BADGE[d.sudo]}</span>
<span class="badge">Interactive: {BOOL_BADGE[d.interactive]}</span>
<span class="badge">Idempotent: {IDEMPOTENT_BADGE.get(d.idempotent, "\u274c")} ({html.escape(d.idempotent)})</span>
</div>
{desc_html}
{deps_html}
{used_by_html}
</div>"""


def build_issues_section(missing_deps: dict[str, list[str]], cycles: list[list[str]],
                          docs_by_path: dict[str, ScriptDoc]) -> str:
    """Render a top-of-page summary of anything wrong with the dependency graph.

    Returns "" (no section at all) when there are no issues -- most repo states won't
    have any, and there is no value in showing an empty "no issues" banner every time.
    """
    if not missing_deps and not cycles:
        return ""

    parts = ['<h2 id="issues">Issues</h2>']

    if missing_deps:
        rows = []
        for relpath, bad in sorted(missing_deps.items()):
            doc = docs_by_path.get(relpath)
            link = f'<a href="#{doc.anchor}"><code>{html.escape(relpath)}</code></a>' if doc else html.escape(relpath)
            bad_list = ", ".join(f"<code>{html.escape(b)}</code>" for b in bad)
            rows.append(f"<li>{link} &rarr; {bad_list}</li>")
        parts.append(
            '<div class="issue-block"><strong class="issue-title dep-missing">'
            f'Missing dependencies ({len(missing_deps)})</strong><ul>{"".join(rows)}</ul></div>'
        )

    if cycles:
        rows = []
        for chain in cycles:
            chain_html = " &rarr; ".join(
                (f'<a href="#{docs_by_path[c].anchor}"><code>{html.escape(c)}</code></a>'
                 if c in docs_by_path else f"<code>{html.escape(c)}</code>")
                for c in chain
            )
            rows.append(f"<li>{chain_html}</li>")
        parts.append(
            '<div class="issue-block"><strong class="issue-title dep-cycle">'
            f'Circular references ({len(cycles)})</strong><ul>{"".join(rows)}</ul></div>'
        )

    return "\n".join(parts)


def build_stats_block(stats: dict) -> str:
    idem = stats["idempotent_counts"]
    dir_rows = "".join(
        f"<tr><td class='dir-tag'>{html.escape(d)}</td><td>{n}</td></tr>"
        for d, n in sorted(stats["by_dir"].items())
    )
    return f"""<h2 id="at-a-glance">At a Glance</h2>
<table>
<thead><tr><th>Metric</th><th>Value</th></tr></thead>
<tbody>
<tr><td>Total scripts</td><td>{stats['total']}</td></tr>
<tr><td>Directories</td><td>{stats['directories']}</td></tr>
<tr><td>Require root / sudo</td><td>{stats['sudo_count']} / {stats['total']}</td></tr>
<tr><td>Interactive</td><td>{stats['interactive_count']} / {stats['total']}</td></tr>
<tr><td>Idempotent (always / mostly / no)</td>
    <td>{idem.get('true', 0)} / {idem.get('mostly', 0)} / {idem.get('false', 0)}</td></tr>
<tr><td>Scripts with dependencies</td><td>{stats['with_deps_count']} / {stats['total']}</td></tr>
</tbody>
</table>
<table>
<thead><tr><th>Directory</th><th>Scripts</th></tr></thead>
<tbody>
{dir_rows}
</tbody>
</table>"""


def build_toc(by_dir: dict[str, list[ScriptDoc]], has_issues: bool = False) -> str:
    top_links = [
        '<li><a href="#at-a-glance">At a Glance</a></li>',
    ]
    if has_issues:
        top_links.append('<li><a href="#issues" class="toc-issues-link">Issues</a></li>')
    top_links += [
        '<li><a href="#repository-structure">Repository Structure</a></li>',
        '<li><a href="#all-scripts">All Scripts</a></li>',
    ]
    dir_links = [
        f'<li><a href="#{dir_anchor(directory)}">{html.escape(directory)}/'
        f'<span class="toc-count"> ({len(by_dir[directory])})</span></a></li>'
        for directory in sorted(by_dir)
    ]
    return f"""<nav class="toc" id="toc" aria-label="On this page">
<div class="toc-title">On this page</div>
<ul>
{''.join(top_links)}
<li class="toc-divider">Directories</li>
{''.join(dir_links)}
</ul>
<a class="toc-back-to-top" href="#top">&uarr; Back to top</a>
</nav>"""


def build_html(docs: list[ScriptDoc], repo_root: str, template: str) -> str:
    by_dir: dict[str, list[ScriptDoc]] = {}
    for d in docs:
        by_dir.setdefault(d.directory, []).append(d)

    docs_by_path = {d.relpath: d for d in docs}
    reverse_deps = build_reverse_dependencies(docs)

    sections = []
    for directory in sorted(by_dir):
        cards = "\n".join(build_script_card(d, docs_by_path, reverse_deps) for d in by_dir[directory])
        anchor = dir_anchor(directory)
        sections.append(
            f'<h2 id="{anchor}" class="dir-heading"><code>{html.escape(directory)}/</code>'
            f'{permalink_html(anchor)}</h2>\n{cards}'
        )

    generated_at = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    stats = compute_stats(docs)
    tree_text = build_tree_text(repo_root)
    missing_deps = find_missing_dependencies(docs)
    cycles = find_circular_dependencies(docs)
    issues_html = build_issues_section(missing_deps, cycles, docs_by_path)

    return render_template(template, {
        "STATS": build_stats_block(stats),
        "ISSUES": issues_html,
        "TREE": html.escape(tree_text),
        "TABLE": build_summary_table(docs),
        "SECTIONS": "".join(sections),
        "TOC": build_toc(by_dir, has_issues=bool(missing_deps or cycles)),
        "GENERATED_AT": generated_at,
        "SCRIPT_COUNT": str(len(docs)),
    })


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", default=os.path.dirname(os.path.abspath(__file__)),
                         help="Repository root to scan (default: this script's directory)")
    parser.add_argument("--out", default=None,
                         help="Output HTML path (default: <root>/docs/index.html)")
    parser.add_argument("--strict", action="store_true",
                         help="Exit with non-zero status if any .sh file is missing a DOC block")
    args = parser.parse_args()

    root = os.path.abspath(args.root)
    out_path = args.out or os.path.join(root, "docs", "index.html")

    template_path = os.path.join(root, "docs", TEMPLATE_NAME)
    if not os.path.isfile(template_path):
        print(f"[!] Template not found: {template_path}", file=sys.stderr)
        return 1
    with open(template_path, "r", encoding="utf-8") as f:
        template = f.read()

    script_paths = find_scripts(root)
    docs: list[ScriptDoc] = []
    undocumented: list[str] = []

    for relpath in script_paths:
        full = os.path.join(root, relpath)
        doc = parse_doc_block(full, relpath)
        if doc is None:
            undocumented.append(relpath)
            continue
        docs.append(doc)

    if undocumented:
        print(f"[!] {len(undocumented)} script(s) missing a DOC-START/DOC-END block:", file=sys.stderr)
        for u in undocumented:
            print(f"    - {u}", file=sys.stderr)

    docs.sort(key=lambda d: d.relpath)

    missing_deps = find_missing_dependencies(docs)
    if missing_deps:
        print(f"[!] {len(missing_deps)} script(s) declare a dependency that doesn't resolve "
              f"to a documented script:", file=sys.stderr)
        for relpath, bad in sorted(missing_deps.items()):
            for dep in bad:
                print(f"    - {relpath} -> {dep}", file=sys.stderr)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(build_html(docs, root, template))

    print(f"[+] Wrote {out_path} ({len(docs)} scripts documented)")

    if args.strict and (undocumented or missing_deps):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
