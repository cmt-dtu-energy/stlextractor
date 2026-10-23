# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

While the major version is `0`, the public API may change between minor
releases. Once the API is considered stable, the package will be released as
`1.0.0` and follow SemVer strictly thereafter.

Note: tags `v0.4.0`, `v0.9.0`, and `v0.10.0` were never published; the
sequence skips directly to the next release.

## [0.15.0] - 2026-10-23

### Fixed
- `HexagonalPrism.write()` (via the renamed `HexagonalPrismTriangulation`,
  formerly `HexagonalPrismFanTriangulation`) produced STL files that
  `STLExtractor` could not re-read. The hexagonal caps were triangulated as
  a single-vertex fan, whose long diagonal is geometrically parallel to two
  of a regular hexagon's own edges, spuriously tripping `STLExtractor`'s
  "exactly one group of 12 parallel edges" check. Caps are now triangulated
  with an ear+center split (matching the project's real STL fixtures)
  instead. Separately, `HexagonalPrism.write()` also failed outright with
  `UndefinedFunction: faceNormal`, since the triangulation strategy class
  only fakes `isa(...,'triangulation')` without implementing the methods
  `stlwrite` calls on it; `write()` now wraps its triangulation in a real
  `triangulation` object first.

## [0.14.0] - 2026-10-23

### Added
- Test coverage for the remaining known failure modes from issue #13: two
  independently valid particles merged into one by a shared vertex (a
  realistic non-manifold scenario), a truncated binary STL, and
  single-particle alignment statistics.

## [0.13.0] - 2026-10-22

### Fixed
- `ExtractedPacking`: `cutoff`/`cutoffz` compared the `Method` option against
  `CutoffMethod` enum members with `strcmp`, which is always false for
  enumeration members, so `CutoffMethod.vertices` silently behaved like
  `CutoffMethod.centers` for every caller. Vertices-based filtering (the
  behavior described under `[0.5.0]`) is now actually applied, which changes
  which particles are kept by `cutoff`/`cutoffz` for existing callers relying
  on the default `Method`.
- `STLExtractor`: a particle whose triangulation does not yield exactly one
  group of 12 parallel edges (i.e. is not a well-formed hexagonal prism) is
  now rejected with an `InvalidParticleGeometry` error, instead of silently
  extracting bogus axial and face-rotation data.

## [0.12.0] - 2026-06-15

### Changed
- Use sparse matrices and a more efficient formulation for the connectivity
  matrix construction.
- Update color table to match the group's publication style; adjust lighting
  for better rendering.

### Fixed
- JSON shell interface: correctly map outlier-filtering options to the
  z-limit parameters.

## [0.11.0] - 2025-11-10

### Added
- New cutoff method selectable via enumeration classes (`CutoffMethod`,
  `CutoffProcedure`) supporting both centers-based and vertices-based
  cutting, for both side and z-direction procedures.
- Option to limit the maximum z-value of particles.

### Changed
- Rename z-direction filtering options to more generic argument names.
- Packing plots now center all coordinates at zero.
- Rendering now uses consistent colors for the same items across calls.
- Simplified the way options are passed between internal functions.
- Updated tutorial Live Script to describe the new cutoff procedures.

## [0.8.0] - 2025-09-30

### Added
- New function to cut a packing in the z-direction only.

## [0.7.0] - 2025-07-04

### Added
- Option to pass a bounding-box length for filtering the packing.
- Error handling around the packing-filter API.

### Changed
- Documented new filtering features in the README.

## [0.6.0] - 2025-07-03

### Added
- Option to filter outlier prisms from an extracted packing.

## [0.5.0] - 2025-07-03

### Added
- `ExtractedPacking` class as the result type returned by `STLExtractor`,
  carrying summary statistics, alignments, cutoff information, and
  serialization support.
- `FanTriangulation` class with associated unit tests.
- Cutoff parameters exposed through the shell (JSON) interface.
- Custom renderer used by the plotting routines; tests reformulated around it.
- Acceptance test for the coloring feature.
- Public `triangulation` property on `HexagonalPrism`, with validation and
  default arguments for `faceRotation` and `triangulation`.
- Error ID for missing triangulation.

### Changed
- Particle filtering algorithm now operates on vertices rather than centers.
- Corrected definitions of weighted summary statistics.
- Removed the scale factor from the pipeline.
- Plotting moved from `STLExtractor` into `ExtractedPacking`.
- Triangulation information made private where appropriate.

### Removed
- Meaningless and impossible tests cleaned up.

## [0.3.0] - 2025-06-09

### Added
- `projectDir` helper function.
- Tests covering larger packings.

### Changed
- Plotting now uses MATLAB triangulation objects directly.
- Extracted and documented the individual-particle processing pipeline
  (`processIndividualParticle` and related methods).
- README revised for clarity.

### Fixed
- Removed failing tests left over from earlier refactors.

## [0.2.0] - 2025-05-14

### Added
- New coloring algorithm based on a function by Andrea Insinga.
- Optional saving of individual STL files.

## [0.1.0] - 2025-03-28

Initial public release.

### Added
- Base classes: `STLExtractor`, `HexagonalPrism`,
  `HexagonalPrismFanTriangulation`, and supporting utilities.
- Parsing of an STL packing into individual hexagonal prisms, with
  detection of radius, axis, thickness, and orientation.
- Connectivity matrix construction with explanatory figures and tests.
- Plotting of extracted packings with per-particle coloring.
- First tutorial Live Script and example STL files generated in Blender.
- Initial test suite, including parametrized tests and a `private/`
  folder of test helpers.
- README and MATLAB Project file.
