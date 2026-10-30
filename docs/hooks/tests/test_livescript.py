"""Tests for docs/hooks/livescript.py's MATLAB-publishing-to-Markdown conversion."""

import json
from textwrap import dedent

from livescript import _captured_block, _figures_prefix, _inline, _load_captured, convert, on_page_markdown


def test_inline_bold():
    assert _inline("do *this* now") == "do **this** now"


def test_inline_italic():
    assert _inline("an _italic_ word") == "an *italic* word"


def test_inline_monospace_untouched_by_bold_italic():
    # |...| spans are verbatim code; markup characters inside them must not
    # be converted.
    assert _inline("see |*not_bold*|") == "see `*not_bold*`"


def test_inline_unbalanced_bars_are_literal():
    assert _inline("a | stray bar") == "a | stray bar"


def test_inline_link():
    text = "see <https://example.com/x link text> for more"
    assert _inline(text) == "see [link text](https://example.com/x) for more"


def test_convert_cell_title_becomes_heading():
    source = "%% My Title\n% prose\ncode;\n"
    out = convert(source)
    assert out.startswith("## My Title")


def test_convert_prose_and_code_are_separated():
    source = dedent(
        """\
        %% Title
        % Some prose with *bold* and _italic_ and |mono| text.
        code_line_1;
        code_line_2;
        """
    )
    out = convert(source)
    assert "**bold**" in out
    assert "*italic*" in out
    assert "`mono`" in out
    assert "```matlab" in out
    assert "code_line_1;" in out
    assert "code_line_2;" in out
    # The prose line must not have leaked into the code fence.
    fence_start = out.index("```matlab")
    assert "Some prose" not in out[fence_start:]


def test_convert_bullet_list():
    source = dedent(
        """\
        %% Title
        % intro
        %
        % * bullet one
        % * bullet two
        code;
        """
    )
    out = convert(source)
    assert "- bullet one" in out
    assert "- bullet two" in out


def test_convert_multiple_cells():
    source = dedent(
        """\
        %% First
        % prose one
        a;
        %% Second
        % prose two
        b;
        """
    )
    out = convert(source)
    assert out.index("## First") < out.index("## Second")
    assert out.index("a;") < out.index("## Second")
    assert "b;" in out


def test_convert_code_only_cell_has_no_empty_fence():
    source = "%% Title\ncode_only;\n"
    out = convert(source)
    assert "```matlab\ncode_only;\n```" in out


def test_on_page_markdown_replaces_marker_and_hoists_title(tmp_path):
    script = tmp_path / "Tutorial1_Extract.m"
    script.write_text(
        dedent(
            """\
            %% Tutorial Title
            % Intro prose.
            setup_code;
            """
        )
    )
    markdown = "Preamble.\n\n<!-- livescript: Tutorial1_Extract.m -->\n"
    config = {"config_file_path": str(tmp_path / "mkdocs.yml")}
    out = on_page_markdown(markdown, page=None, config=config, files=None)
    assert out.startswith("# Tutorial Title")
    assert "Preamble." in out
    assert "Intro prose." in out
    assert "setup_code;" in out


def test_on_page_markdown_without_marker_is_unchanged():
    markdown = "# Just a normal page\n\nNo marker here.\n"
    out = on_page_markdown(markdown, page=None, config={}, files=None)
    assert out == markdown


def test_captured_block_renders_output_and_figures():
    entry = {"index": 0, "output": "hello\n", "figures": ["cell_000_1.png"]}
    out = "\n".join(_captured_block(entry, "captured_figures"))
    assert "```text\nhello\n```" in out
    assert "![Figure](captured_figures/cell_000_1.png)" in out


def test_captured_block_skips_empty_output():
    entry = {"index": 0, "output": "", "figures": []}
    assert _captured_block(entry, "captured_figures") == []


def test_captured_block_accepts_matlab_jsonencode_scalar_figure_quirk():
    # MATLAB's jsonencode collapses a 1-element array to a bare JSON value
    # (observed: a single-figure cell's "figures" field came back as the
    # string "cell_006_1.png" instead of ["cell_006_1.png"]) unless the
    # MATLAB side explicitly uses a cell array. capture_one_cell.m does
    # that, but guard defensively here too: a list is required.
    entry = {"index": 0, "output": "", "figures": ["only_one.png"]}
    out = "\n".join(_captured_block(entry, "captured_figures"))
    assert "![Figure](captured_figures/only_one.png)" in out


def test_load_captured_reads_entries_keyed_by_index(tmp_path):
    entries_dir = tmp_path / "captured_entries"
    entries_dir.mkdir()
    (entries_dir / "cell_000.json").write_text(
        json.dumps({"index": 0, "output": "a", "figures": []})
    )
    (entries_dir / "cell_001.json").write_text(
        json.dumps({"index": 1, "output": "b", "figures": ["x.png"]})
    )
    captured = _load_captured(tmp_path / "Tutorial1_Extract.m")
    assert captured[0]["output"] == "a"
    assert captured[1]["figures"] == ["x.png"]


def test_load_captured_missing_directory_returns_empty(tmp_path):
    assert _load_captured(tmp_path / "Tutorial1_Extract.m") == {}


def test_figures_prefix_relative_to_docs_dir(tmp_path):
    docs_dir = tmp_path / "docs"
    source = docs_dir / "tutorials" / "Tutorial1_Extract.m"
    config = {"docs_dir": str(docs_dir)}
    assert _figures_prefix(source, config) == "tutorials/captured_figures"


def test_convert_interleaves_captured_output_and_figure():
    source = dedent(
        """\
        %% Title
        % prose
        l.plot;
        """
    )
    captured = {0: {"index": 0, "output": "", "figures": ["cell_000_1.png"]}}
    out = convert(source, captured, "tutorials/captured_figures")
    assert "![Figure](tutorials/captured_figures/cell_000_1.png)" in out
    # The figure markdown must come after the code fence, not before it.
    assert out.index("```matlab") < out.index("![Figure]")


def test_convert_without_captured_data_is_unaffected():
    source = "%% Title\n% prose\ncode;\n"
    assert convert(source) == convert(source, captured=None)
    assert convert(source) == convert(source, captured={})
