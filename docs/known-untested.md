# Known-Untested Code

Companion to the failure-mode tests added for issue #13. Coverage is measured by
running `coverage` in the MATLAB Command Window; the HTML report under
`coverageReport/` is not checked in, so this file is the durable record of what
the suite deliberately does not exercise.

Measured on 2026-10-23 with MATLAB R2024b, on branch `develop`, after fixing
issue #26: `HexagonalPrismTriangulation` (renamed from
`HexagonalPrismFanTriangulation`) now triangulates each hexagonal cap with
an ear+center split instead of a single-vertex fan, and `HexagonalPrism.write`
wraps its triangulation in a real `triangulation` object before calling
`stlwrite` (the custom strategy class only fakes `isa(...,'triangulation')`
and doesn't implement methods like `faceNormal` that `stlwrite` needs). All
39 tests pass. Overall statement coverage of the measured files improved to
**87.2%** (the same file set `coverage.m` measures, i.e. every top-level
`.m` except `coverage.m`, `Contents.m`, `CutoffMethod.m`, and
`CutoffProcedure.m`) — the new round-trip test and the extra line in
`HexagonalPrism.write` are both fully exercised.

| File | Statements covered |
| --- | --- |
| `STLExtractor.m` | 115/117 |
| `STLExtractorError.m` | 36/38 |
| `ExtractedPacking.m` | 112/147 |
| `STLextractToJSON.m` | 26/29 |
| `HexagonalPrism.m` | 20/20 |
| `ColorFromHorPsiTheta01.m` | 0/13 |
| `HexagonalPrismTriangulation.m` | 41/41 |
| `PackingFigureRenderer.m` | 16/16 |
| `GeometricType.m` | 5/5 |
| `projectDir.m` | 1/1 |
| `vecnormalize.m` | 3/3 |

## Untested by design

These branches are known gaps, not oversights. Each is either untestable without
a display, redundant with a covered path, or gated on a decision that has not
been made yet.

### Figure and colour rendering

- `ExtractedPacking.m:94-124` — `plot`. Opens a figure and calls `trisurf` per
  particle. Needs a display and produces no assertable return value; the colour
  logic it delegates to is covered separately by `testPackingFigureRenderer`.
- `ColorFromHorPsiTheta01.m` (whole file, 0/13) — legacy colour helper. Grepping
  the repository finds no caller at all, including from `PackingFigureRenderer`,
  so it is unreachable rather than merely untested. This is a removal candidate,
  not a testing gap; see "Open questions" below.

### Disk output

- `STLExtractor.m:317-319` — the `shouldSave` branch of the per-particle STL
  writer. Every test constructs `STLExtractor` with `"ShouldSave", false` to keep
  the suite from writing to disk. The triangulation being written is the same
  object asserted on in the covered path.

### Redundant validation branches

- `STLExtractorError.m:85-86` — `mustBeFolder` with a non-empty `context`. The
  no-context message on the same code path is covered by `testMustBeFolder`; only
  the string interpolation differs.
- `STLExtractorError.m:212` — same pattern for `mustBeValidTriangulation`.
- `HexagonalPrism.m:50` — `write`, a one-line `stlwrite` wrapper.
- `ExtractedPacking.m:252-253` — `filterPacking` argument defaults for `vmin` and
  `vmax`; every caller passes both explicitly.

### Untested error paths

These are reachable and worth covering eventually, but no test drives them yet.

- `ExtractedPacking.m:148-149` — `InvalidDirection` in `cutoff`. Unreachable
  through the public API as written, because `startDirection` is already
  constrained by `mustBeMember` upstream; the `otherwise` arm is defensive.
- `STLextractToJSON.m:41-42` — `FileOpenFailed`. Needs an unwritable output path.
- `STLextractToJSON.m:49` — the `catch` block's wrap-as-`UnhandledError` arm.
  Needs an error from inside the `try` whose identifier doesn't start with
  `STLExtractor:`.
- `STLExtractor.m:120` — the `nParticles = max(obj.pointsInParticle)` branch
  for an empty `pointsInParticle` (i.e. a triangulation with zero points).
  Unreachable through the public file-based API: `stlread` already throws
  `MATLAB:polyfun:stlInvalidData`/`stlFailedToRead` for a facet-less or empty
  STL before `extractIndividualParticles` ever runs (see
  `test_rejects_empty_stl_input` and `test_rejects_valid_stl_with_no_facets`
  in `tests/testSTLExtractor.m`).

### Untested feature paths

- `ExtractedPacking.m:68-75` — the `BoundingBoxLength` filter in `process`. The
  option is threaded through `STLextractToJSON` but no test supplies a value that
  actually trips the `xlim`/`ylim` comparisons.
- `ExtractedPacking.m:143-146` — the `"y"` and `"z"` arms of `cutoff`. Only `"x"`
  is exercised; the arms are structurally identical.
- `STLextractToJSON.m:35` — the `Cutoff > 0` branch that applies `ep.cutoff(...)`.
  No test passes a nonzero `Cutoff` through this entry point.

## Open questions

Items found while measuring this are not just coverage gaps and should be
resolved rather than recorded:

1. **`ColorFromHorPsiTheta01.m` is orphaned.** No file in the repository calls it.
   It looks like leftover code from before `PackingFigureRenderer` existed and can
   probably be deleted.

`CutoffMethod.vertices` being dead (previously listed here) was fixed under
issue #24: `ExtractedPacking.m:264` now compares with `==` instead of
`strcmp`, `tests/testExtractedPacking.m` exercises both `CutoffMethod` arms
directly, and `cutoffz` is no longer an untested feature path above.

`HexagonalPrism.write()` producing STL files `STLExtractor` could not
re-read (previously listed here) was fixed under issue #26: the cap
triangulation in `HexagonalPrismTriangulation` (renamed from
`HexagonalPrismFanTriangulation`) now uses an ear+center split instead of a
single-vertex fan, so it no longer creates a spurious second group of 12
parallel edges. `tests/testHexagonalPrism.m` now exercises the full
`write()` → `STLExtractor.process()` round trip.

`ExtractedPacking.m:286-287` (`NoParticlesInRange` in `filterPacking`) and
`STLextractToJSON.m:25` (the `RemoveOutlierRangeZ` true arm) and `:51` (the
`rethrow` arm of the `catch` block), all previously listed here, are no
longer gaps: a GitHub Copilot coding-agent change to
`tests/testSTLextractToJSON.m` added a `verifyError` assertion that calls
`STLextractToJSON` with default options against a fixture particle that
straddles the default `ZMinLimit=0` boundary, so it is excluded by the
issue #24 vertices-based filtering fix, leaving no particles and tripping
`NoParticlesInRange` — which `STLextractToJSON`'s `catch` block rethrows
unchanged, since its identifier already starts with `STLExtractor:`.
