# Run MATLAB in docs CI to capture live tutorial output

The Tutorial page is rendered from `Tutorial1_Extract.m` by a custom MkDocs
hook that only parses the source text — it never executes MATLAB, so the
published page shows code and prose but none of the `disp`/`fprintf` output
or the ~6 figures the tutorial actually produces (`l.plot`, the four cutoff
`.plot()` calls, the JSON read-back). This is inconsistent with the
Quickstart page, which hardcodes real captured output and a screenshot.

We decided the Tutorial page needs the same: real captured output and
figures for every cell that produces one, not just prose describing what
they'd look like.

We will add a MATLAB step to `.github/workflows/docs.yml` (reusing
`matlab-actions/setup-matlab@v3`, already proven in `tests.yml` under
MathWorks' free hosted licensing for this public repo) that runs
`Tutorial1_Extract.m` and captures each cell's text output and figures on
every docs build, rather than committing manually-captured output as a
sidecar file or reading pre-captured output out of the `.mlx`'s own saved
state. This keeps the published tutorial self-correcting — it cannot drift
from what the code actually does — at the cost of overturning the design
note in `docs.yml` that the Docs workflow needs no MATLAB license, and
adding MATLAB execution time to every docs build.

## Considered options

- **Commit manually-captured sidecar output.** A maintainer runs the
  tutorial locally and commits captured text/figures next to the source
  (as already done for Quickstart's numbers and screenshot). Rejected:
  output silently goes stale whenever the tutorial changes without someone
  remembering to re-capture it.
- **Read captured output from the `.mlx`'s own saved cell state.** The Live
  Script format already embeds output when run and saved in the MATLAB Live
  Editor. Rejected in favor of a CI-driven run so freshness doesn't depend
  on a human remembering to save the `.mlx` with outputs visible before
  committing.

## Consequences

- `.github/workflows/docs.yml`'s comment ("no MATLAB license is needed")
  needed updating; it no longer holds.
- `docs/tutorials/capture_output.m` executes each cell of
  `Tutorial1_Extract.m` in its own `matlab -batch` process (via
  `capture_one_cell.m`), chaining variables between cells through a saved
  `.mat` checkpoint, rather than running the whole script in one shared
  session. This is a deliberate workaround, not the obvious approach: a
  single shared session reliably hung partway through (specifically on the
  cell that creates two figures, after several prior output-capture/figure
  cycles in that same process). The exact cause was not root-caused — that
  same cell runs fine on its own, in a fresh session — so a future reader
  simplifying this back to one session should expect to reproduce the hang.
  The cost is roughly one MATLAB startup per cell (~23 for this tutorial)
  instead of one for the whole run.
- Output lands in `docs/tutorials/captured_entries/*.json` (one file per
  cell: `{index, output, figures}`) and `captured_figures/*.png`, both
  gitignored and regenerated on every docs build; `docs/hooks/livescript.py`
  reads them back in and interleaves them after each cell's code block.
