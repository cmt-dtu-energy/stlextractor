"""MkDocs hook: render MATLAB help text as Markdown in the API reference.

mkdocstrings-matlab passes each help block through as Markdown, but MATLAB help
text follows its own conventions (an upper-case H1 line, indented calling
syntax, ``Example:`` blocks, ``See also`` lines), so rendered verbatim all of
its line structure is lost. This hook wraps the handler's docstring
construction (``maxx.treesitter.Docstring``, pinned in docs/requirements.txt)
and converts each help block before it is rendered:

* the H1 line becomes a summary paragraph, without the repeated NAME;
* calling-syntax lines such as ``ep = PROCESS(obj,'ZMinLimit',z)`` start their
  own paragraph, with the syntax shown as code in its real capitalisation;
* lines under ``Example:`` become a MATLAB code block;
* names of documented classes/functions are shown as code, and the ones in
  ``See also`` link to their API pages.
"""

from __future__ import annotations

import re
from pathlib import Path

from mkdocs.exceptions import PluginError

# Upper-case name -> real name, for every documented top-level .m file.
_ROOT = Path(__file__).resolve().parents[2]
_NAMES: dict[str, str] = {p.stem.upper(): p.stem for p in _ROOT.glob("*.m")}
# Upper-case name -> real name, for every function and method defined there.
_FUNCTIONS: dict[str, str] = {
    name.upper(): name
    for p in _ROOT.glob("*.m")
    for name in re.findall(
        r"^\s*function\s+(?:[^=(]*=\s*)?(\w+)", p.read_text(errors="replace"), re.M
    )
}


def _install() -> None:
    # Runs at import time: mkdocstrings-matlab parses the MATLAB sources while
    # the plugin is being configured, before any hook event fires.
    try:
        import maxx.treesitter as treesitter
    except ImportError as exc:
        raise PluginError(f"matlab_help hook: cannot import maxx ({exc})") from exc
    original = getattr(treesitter, "Docstring", None)
    if original is None:
        raise PluginError("matlab_help hook: maxx.treesitter.Docstring not found")
    if getattr(original, "_matlab_help", False):
        return

    def docstring(value, *args, **kwargs):
        return original(help_to_markdown(value), *args, **kwargs)

    docstring._matlab_help = True
    treesitter.Docstring = docstring


_H1 = re.compile(r"^([A-Z][A-Z0-9_]+)\s+(?=[A-Z])")
_SIGNATURE = re.compile(
    r"^((?:\[[^\]]*\]|[A-Za-z]\w*)\s*=\s*)?"  # optional outputs
    r"([A-Za-z][\w.]*)"  # function or method name
    r"(\((?:[^()]|\([^()]*\))*\))"  # argument list (one level of nesting)
)
_EXAMPLE = re.compile(r"^(usage\s+)?examples?:$", re.IGNORECASE)
_HEADER = re.compile(r"^[A-Z][A-Z ]+:$")
_SEE_ALSO = re.compile(r"^see also:?\s*(.*)$", re.IGNORECASE)
_UPPER_NAME = re.compile(r"\b([A-Z][A-Z0-9_]{3,})(?:([./])([A-Z][A-Z0-9_]*))?\b")


def help_to_markdown(text: str) -> str:
    lines = text.splitlines()
    if not lines:
        return text
    blocks: list[str] = []

    first = lines[0].strip()
    match = _H1.match(first)
    if match:
        first = first[match.end():]
    rest = lines[1:]
    # The H1 line occasionally wraps onto a lower-case continuation line.
    summary = [first]
    while rest and rest[0].strip()[:1].islower() and not _starts_block(rest[0]):
        summary.append(rest.pop(0).strip())
    if len(lines) == 1:
        return _prose(" ".join(summary))
    blocks.append(_prose(" ".join(summary)))

    paragraph: list[str] = []
    indent = 0
    code: list[str] | None = None
    code_indent = 0
    items: list[tuple[int, list[str]]] = []

    def flush() -> None:
        nonlocal paragraph, code, items
        if paragraph:
            blocks.append(_paragraph(" ".join(paragraph)))
            paragraph = []
        if code:
            blocks.append("```matlab\n" + "\n".join(_dedent(code)) + "\n```")
        code = None
        if items:
            base = min(level for level, _ in items)
            blocks.append(
                "\n".join(
                    "    " * min(level - base, 2) + "- " + _prose(" ".join(words))
                    for level, words in items
                )
            )
            items = []

    for raw in rest:
        stripped = raw.strip()
        level = len(raw) - len(raw.lstrip())
        if not stripped:
            if code is None:
                flush()
            elif code:
                flush()
            continue
        if code is not None:
            if level > code_indent:
                code.append(raw)
                continue
            flush()
        if _EXAMPLE.match(stripped):
            flush()
            blocks.append("**Example**")
            code, code_indent = [], level
            continue
        see_also = _SEE_ALSO.match(stripped)
        if see_also:
            flush()
            blocks.append("**See also:** " + _see_also(see_also.group(1)))
            continue
        if _HEADER.match(stripped):
            flush()
            blocks.append(f"**{stripped[:-1].capitalize()}**")
            continue
        if stripped.startswith(("- ", "* ")):
            if paragraph:
                flush()
            items.append((level, [stripped[2:]]))
            continue
        if items:
            if level > items[-1][0]:
                items[-1][1].append(stripped)
                continue
            flush()
        if paragraph and level <= indent and _SIGNATURE.match(stripped):
            flush()
        if not paragraph:
            indent = level
        paragraph.append(stripped)
    flush()
    return "\n\n".join(block for block in blocks if block)


def _starts_block(line: str) -> bool:
    stripped = line.strip()
    return bool(
        _SIGNATURE.match(stripped)
        or _EXAMPLE.match(stripped)
        or _SEE_ALSO.match(stripped)
        or _HEADER.match(stripped)
        or stripped.startswith(("- ", "* "))
    )


def _paragraph(text: str) -> str:
    """A paragraph, with a leading calling syntax rendered as code."""
    match = _SIGNATURE.match(text)
    if not match:
        return _prose(text)
    outputs, name, args = match.groups()
    signature = (outputs or "") + _real_name(name) + args
    return f"`{signature}`" + _prose(text[match.end():])


def _prose(text: str) -> str:
    text = text.replace("<", "&lt;").replace(">", "&gt;")
    return _UPPER_NAME.sub(_name_span, text)


def _name_span(match: re.Match) -> str:
    name, sep, member = match.groups()
    if name not in _NAMES:
        return match.group(0)
    if member:
        return f"`{_NAMES[name]}.{member.lower()}`"
    return f"`{_NAMES[name]}`"


def _see_also(text: str) -> str:
    links = []
    for item in re.split(r"\s*,\s*", text.strip().rstrip(".")):
        if not item:
            continue
        name, member = _split_member(item)
        real = _NAMES.get(name.upper())
        if real is None:
            links.append(f"`{item}`")
        elif member:
            links.append(f"[`{real}.{member.lower()}`][{real}.{member.lower()}]")
        else:
            links.append(f"[`{real}`][{real}]")
    return ", ".join(links)


def _split_member(item: str) -> tuple[str, str]:
    name, _, member = item.replace("/", ".").partition(".")
    return name, member


def _real_name(name: str) -> str:
    head, _, tail = name.partition(".")
    if head.isupper():
        head = _NAMES.get(head, _FUNCTIONS.get(head, head.lower()))
    if tail and tail.isupper():
        tail = _FUNCTIONS.get(tail, tail.lower())
    return head + ("." + tail if tail else "")


def _dedent(lines: list[str]) -> list[str]:
    width = min(len(line) - len(line.lstrip()) for line in lines if line.strip())
    return [line[width:] for line in lines]


_install()
