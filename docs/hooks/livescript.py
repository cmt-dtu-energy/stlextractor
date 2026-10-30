"""MkDocs hook: render a MATLAB Live Script source (.m with %% cells) as Markdown.

A page containing the marker

    <!-- livescript: docs/tutorials/Tutorial1_Extract.m -->

has the marker replaced by the script converted with MATLAB's publishing
markup rules: each ``%%`` line starts a cell (its title becomes a heading),
the comment lines right after it are prose, and everything else in the cell
is code. This keeps the docs page in sync with the tutorial script instead of
maintaining a second copy.

If a sibling ``captured_entries/`` directory exists next to the source
script (written by ``capture_output.m`` -- see ADR 0001), each cell's real
printed output and any figures it produced are interleaved after its code
block, so the page shows what the tutorial actually does rather than just
its source.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

MARKER = re.compile(r"<!--\s*livescript:\s*(\S+)\s*-->")


def on_page_markdown(markdown, page, config, files):
    match = MARKER.search(markdown)
    if not match:
        return markdown
    path = Path(config["config_file_path"]).parent / match.group(1)
    captured = _load_captured(path)
    figures_prefix = _figures_prefix(path, config)
    body = convert(path.read_text(encoding="utf-8"), captured, figures_prefix)
    # The script's first cell title becomes the page title, placed above any
    # content that precedes the marker on the page.
    title = ""
    if body.startswith("## "):
        heading, _, body = body.partition("\n")
        title = "#" + heading[2:] + "\n\n"
    return title + markdown[: match.start()] + body + markdown[match.end():]


def _load_captured(source_path: Path) -> dict[int, dict]:
    """Read capture_output.m's per-cell JSON entries, keyed by cell index."""
    entries_dir = source_path.parent / "captured_entries"
    if not entries_dir.is_dir():
        return {}
    captured: dict[int, dict] = {}
    for entry_file in sorted(entries_dir.glob("cell_*.json")):
        entry = json.loads(entry_file.read_text(encoding="utf-8"))
        captured[entry["index"]] = entry
    return captured


def _figures_prefix(source_path: Path, config) -> str:
    """The captured_figures/ path, relative to the page's own directory."""
    docs_dir = Path(config.get("docs_dir", source_path.parents[2] / "docs"))
    try:
        rel = source_path.parent.relative_to(docs_dir)
    except ValueError:
        rel = Path(source_path.parent.name)
    return str(rel / "captured_figures")


def on_serve(server, config, builder):
    root = Path(config["config_file_path"]).parent
    server.watch(str(root / "docs" / "tutorials"))
    return server


def convert(
    source: str,
    captured: dict[int, dict] | None = None,
    figures_prefix: str = "captured_figures",
) -> str:
    out: list[str] = []
    for index, (title, lines) in enumerate(_split_cells(source.splitlines())):
        if title:
            out.append("## " + _inline(title))
            out.append("")
        prose, code = _split_prose(lines)
        if prose:
            out.extend(_prose(prose))
            out.append("")
        code = _strip_blank(code)
        if code:
            out.append("```matlab")
            out.extend(code)
            out.append("```")
            out.append("")
        if captured and index in captured:
            out.extend(_captured_block(captured[index], figures_prefix))
    return "\n".join(out)


def _captured_block(entry: dict, figures_prefix: str) -> list[str]:
    """Render one cell's real output text and figures, captured by
    capture_output.m: a fenced text block for anything printed, and an
    image for each figure the cell produced."""
    out: list[str] = []
    text = (entry.get("output") or "").strip("\n")
    if text:
        out.append("*Output:*")
        out.append("")
        out.append("```text")
        out.append(text)
        out.append("```")
        out.append("")
    for figure in entry.get("figures") or []:
        out.append(f"![Figure]({figures_prefix}/{figure})")
        out.append("")
    return out


def _split_cells(lines: list[str]) -> list[tuple[str, list[str]]]:
    cells: list[tuple[str, list[str]]] = []
    for line in lines:
        if line.startswith("%%"):
            cells.append((line[2:].strip(), []))
        elif cells:
            cells[-1][1].append(line)
        else:
            cells.append(("", [line]))
    return cells


def _split_prose(lines: list[str]) -> tuple[list[str], list[str]]:
    """Leading comment lines of a cell are prose; the rest is code."""
    n = 0
    while n < len(lines) and lines[n].startswith("%"):
        n += 1
    return [line[1:] for line in lines[:n]], lines[n:]


def _prose(lines: list[str]) -> list[str]:
    """Convert a prose block into Markdown paragraphs, lists and code blocks."""
    out: list[str] = []
    para: list[str] = []  # lines of the current paragraph or list item
    bullet = False
    pre: list[str] = []

    def flush_para() -> None:
        nonlocal para, bullet
        if para:
            text = _inline(" ".join(para))
            if bullet:
                out.append("- " + text)
            else:
                if out and out[-1] != "":
                    out.append("")
                out.append(text)
        para, bullet = [], False

    def flush_pre() -> None:
        nonlocal pre
        if pre:
            if out and out[-1] != "":
                out.append("")
            out.extend(["```matlab", *pre, "```", ""])
        pre = []

    for line in lines:
        text = line.strip()
        if line.startswith("  ") and text:
            # Two or more leading spaces mark preformatted text.
            flush_para()
            pre.append(text)
            continue
        flush_pre()
        if not text:
            flush_para()
            if out and out[-1] != "":
                out.append("")
        elif text.startswith("* "):
            was_bullet = bullet
            flush_para()
            if not was_bullet and out and out[-1] != "" and not out[-1].startswith("- "):
                out.append("")
            para, bullet = [text[2:]], True
        else:
            para.append(text)
    flush_para()
    flush_pre()
    return _strip_blank(out)


def _strip_blank(lines: list[str]) -> list[str]:
    while lines and not lines[0].strip():
        lines = lines[1:]
    while lines and not lines[-1].strip():
        lines = lines[:-1]
    return lines


_LINK = re.compile(r"<(https?://\S+)\s+([^>]+)>")
_BOLD = re.compile(r"(?<![\w*])\*(?=\S)([^*]+?)(?<=\S)\*(?![\w*])")
_ITALIC = re.compile(r"(?<!\w)_(?=\S)([^_]+?)(?<=\S)_(?!\w)")


def _inline(text: str) -> str:
    """Convert MATLAB markup to Markdown, leaving |monospace| spans untouched."""
    parts = text.split("|")
    if len(parts) % 2 == 0:  # unbalanced bars: treat literally
        parts = [text]
    for i, part in enumerate(parts):
        if i % 2:
            parts[i] = f"`{part}`"
        else:
            part = _LINK.sub(r"[\2](\1)", part)
            part = _BOLD.sub(r"**\1**", part)
            parts[i] = _ITALIC.sub(r"*\1*", part)
    return "".join(parts)
