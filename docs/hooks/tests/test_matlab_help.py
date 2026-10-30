"""Tests for docs/hooks/matlab_help.py's MATLAB-help-to-Markdown conversion.

These exercise help_to_markdown() directly against the conventions described
in the module docstring (H1 line, calling syntax, Example blocks, See also),
rather than going through a full mkdocs build.
"""

from textwrap import dedent

import matlab_help
from matlab_help import help_to_markdown


def test_module_import_installs_docstring_patch():
    # _install() runs at import time; if maxx's API shape ever changes this
    # raises PluginError during collection instead of silently no-op'ing.
    import maxx.treesitter as treesitter

    assert getattr(treesitter.Docstring, "_matlab_help", False) is True
    assert matlab_help  # module imported without raising


def test_h1_line_becomes_summary_without_repeated_name():
    text = "STLEXTRACTOR Extract individual hexagonal prisms from a packed STL file"
    assert help_to_markdown(text) == (
        "Extract individual hexagonal prisms from a packed STL file"
    )


def test_calling_syntax_rendered_as_code_with_real_casing():
    text = dedent(
        """\
        STLEXTRACTOR Short summary.

        ep = PROCESS(obj,'ZMinLimit',zmin) does something with zmin.
        """
    ).rstrip("\n")
    out = help_to_markdown(text)
    assert "`ep = process(obj,'ZMinLimit',zmin)`" in out
    assert "does something with zmin." in out


def test_example_block_becomes_matlab_code_fence():
    text = dedent(
        """\
        STLEXTRACTOR Does something.

        Example:
           x = 1;
           y = 2;
        """
    ).rstrip("\n")
    out = help_to_markdown(text)
    assert "**Example**" in out
    assert "```matlab\nx = 1;\ny = 2;\n```" in out


def test_see_also_links_known_names():
    text = "STLEXTRACTOR Summary line.\n\nSee also: ExtractedPacking, HexagonalPrism"
    out = help_to_markdown(text)
    assert "[`ExtractedPacking`][ExtractedPacking]" in out
    assert "[`HexagonalPrism`][HexagonalPrism]" in out


def test_known_uppercase_name_becomes_code_span_in_prose():
    text = "STLEXTRACTOR Does X.\n\nUse STLEXTRACTOR to process files."
    out = help_to_markdown(text)
    assert "Use `STLExtractor` to process files." in out


def test_unknown_uppercase_name_is_left_untouched():
    text = "STLEXTRACTOR Does X.\n\nSee FOOBARBAZ for details."
    out = help_to_markdown(text)
    assert "FOOBARBAZ" in out
    assert "`FOOBARBAZ`" not in out


def test_empty_text_returned_unchanged():
    assert help_to_markdown("") == ""
