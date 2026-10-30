# stlextractor - version 0.15.0

[![Docs](https://github.com/cmt-dtu-energy/stlextractor/actions/workflows/docs.yml/badge.svg)](https://cmt-dtu-energy.github.io/stlextractor/)
[![Tests](https://github.com/cmt-dtu-energy/stlextractor/actions/workflows/tests.yml/badge.svg)](https://github.com/cmt-dtu-energy/stlextractor/actions/workflows/tests.yml)

**Documentation:** <https://cmt-dtu-energy.github.io/stlextractor/>

MATLAB package to process a large STL file containing a packing of multiple hexagonal
prisms (the only supported form at the moment) and parse each prism,
identifying its geometric parameters such as radius, axis, volume etc.

Each individual prism can then be written to its own STL file, or have its info
made available to other MATLAB programs.

Motivation: we want to simulate packings of particles, but want to assign different
properties to each prism. With `STLExtractor`, we can generate the packing
in a geometric modeling software, and have the library parse this purely geometric info;
the individual objects can then be used in a MATLAB project that treats the orientation, radius
or thickness as parameters for some other property (e.g. assigning all particles of a given radius
a certain mechanical strength). Alternatively, you can just use the project
to save the individual STL files and import them into a simulation software, manually setting
up different parameters.


## Installation

<!-- --8<-- [start:install] -->
Clone this repo to a location of choice, then add it to the MATLAB path. From
the MATLAB Command Window:

```matlab
addpath("/path/to/stlextractor")
% optionally, make this permanent across MATLAB sessions:
savepath
```
<!-- --8<-- [end:install] -->

## Quickstart

<!-- --8<-- [start:quickstart] -->
The snippet below can be copy-pasted into the MATLAB Command Window right
after cloning the repo (it uses one of the small STL fixtures bundled with
the test suite, so no external files are needed):

```matlab
addpath("/path/to/stlextractor")

% a small bundled STL file containing a packing of 48 hexagonal prisms
testFile = fullfile(projectDir, "tests", "test_stl_files", "particles_48.stl");

extractor = STLExtractor(testFile, [], "ShouldSave", false);
packing = extractor.process();

fprintf("Extracted %d particles\n", length(packing));

firstPrism = packing.items(1);
fprintf("First particle: radius = %.3f, thickness = %.3f\n", ...
    firstPrism.radius, firstPrism.thickness);
fprintf("Filling fraction: %.3f\n", packing.volumetricFillingFraction);

% render the whole packing in a 3-D figure
packing.plot();
```

(`projectDir` is a small helper function shipped with the package that
returns the repo's root folder, so the snippet works regardless of your
current working directory.)
<!-- --8<-- [end:quickstart] -->

For a longer walkthrough (filtering, saving individual STL files, JSON
export), see the [Tutorial](https://cmt-dtu-energy.github.io/stlextractor/tutorial/).

`stlextractor` has been tested on Windows, macOS and Linux, with MATLAB versions >= 2024a.

## Usage

See the [Tutorial](https://cmt-dtu-energy.github.io/stlextractor/tutorial/) on the
documentation site, or the example [Live Script](./docs/tutorials/Tutorial1_Extract.mlx), for examples of using
the package (you need to add the [tutorials](./docs/tutorials/) folder to the MATLAB
path for it to run correctly, or to change the current folder to this path).

The API is class-based. Check out the documentation for the `STLExtractor` class,
which is the main entry-point for reading an STL file. The result of actually
parsing and processing the file is an instance of `ExtractedPacking`.

## Public API overview

A quick map of the main public entry points (see the
[API Reference](https://cmt-dtu-energy.github.io/stlextractor/api/) for the
full function reference, or run `help <name>` in MATLAB):

- **`STLExtractor`** — main entry point. Construct with
  `STLExtractor(filename, saveDir, "ShouldSave", false)`, then call
  `.process(...)` to read the STL file, group its triangles into individual
  hexagonal prisms, and return an `ExtractedPacking`.
- **`ExtractedPacking`** — the result of processing a file: a collection of
  `HexagonalPrism` objects (`.items`), together with bounding-box, volume,
  filling-fraction and alignment statistics for the whole packing. Supports
  `length(...)`, `.plot()`, `.cutoff(...)` and `.filterPacking(...)` to trim
  the packing further.
- **`HexagonalPrism`** — a single extracted particle, exposing its geometric
  parameters (`radius`, `thickness`, `position`, `normal`, `volume`, `area`,
  `vertices`) and a `.write(filename)` method to save it as its own STL file.
- **`STLextractToJSON(input, output, ...)`** — a function wrapper intended for
  non-interactive/command-line use: reads an STL file, processes it, and
  serializes the resulting `ExtractedPacking` to a JSON file. See the
  [I/O](#io) section below for its options.

## Known limitations

- **Hexagonal prisms only.** The extractor only recognizes particles shaped
  as hexagonal prisms; no other geometric primitive is currently supported.
- **Expected STL structure.** The input STL file is assumed to contain one or
  more particles, where each particle is a *single connected component* of
  triangles (i.e. particles must not touch or share vertices/edges with each
  other). Within each connected component, the extractor expects to find
  exactly one group of 12 mutually parallel edges, which it uses to determine
  the prism's axis and height; if a connected component does not match this
  pattern, extraction fails with an `STLExtractor:InvalidParticleGeometry`
  error.
- **Platform/version status is unverified.** The package is developed and
  exercised on macOS and Linux; behavior on Windows has not been verified
  (tracked in issue #14). Likewise, the minimum supported MATLAB release and
  the exact set of required toolboxes have not yet been pinned down (tracked
  in issue #15). Treat both as open questions rather than assumptions.

## Testing

- Run `runtests("tests")` in the MATLAB Command Window to run the test suite.
- Run `coverage` in the MATLAB Command Window to run the tests and open a test coverage report
- See [docs/known-untested.md](docs/known-untested.md) for the branches the suite deliberately does not cover


## Documentation site

The [documentation site](https://cmt-dtu-energy.github.io/stlextractor/) is
built with [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) by
the `Docs` workflow and published to GitHub Pages on every push to `main`. The
API reference is generated from the MATLAB help text, the Quickstart and
Installation sections are included from this README, and the Tutorial page is
rendered from `docs/tutorials/Tutorial1_Extract.m`. To preview it locally:

```sh
pip install -r docs/requirements.txt
mkdocs serve
```

## Versioning

This package follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(`MAJOR.MINOR.PATCH`). While at `0.x`, minor releases may introduce breaking
changes; downstream projects should pin to a specific tag.

The version is declared in three places and must be kept in sync on every
release:

1. `Contents.m` — `% Version X.Y.Z DD-Mon-YYYY` (queryable via `ver('STLExtractor')`)
2. `README.md` — the title line
3. A Git tag of the form `vX.Y.Z`, with a matching entry in `CHANGELOG.md`

Release procedure:

```sh
# 1. Update Contents.m, README.md, and CHANGELOG.md (move Unreleased -> X.Y.Z)
git commit -am "Release vX.Y.Z"
git tag vX.Y.Z
git push && git push --tags
# 2. Cut a GitHub Release from the tag, pasting the CHANGELOG section as notes.
```

## I/O

To automate the extraction process and integrate with other programs,
you can use `STLextractToJSON(input,output)`, which will:

- read an STL file `input`;
- process it;
- serialize the information about the extracted particles in `output`

The intended usage is to run from the command line (after installing the package
according to the instructions above). In the simplest case, to just read an STL file
and write the output to a JSON file, you can use the following command:

```shell
matlab -batch 'STLextractToJSON("input.stl","output.json")'
```

The first argument must be an existing STL file, and the second must be in a writable
directory. The output file will contain a JSON encoding of the `ExtractedPacking` object.

By default, this command does some post-processing: all particles that have any vertices
below the $z=0$ plane are removed. To control this behavior, you can
pass additional options:

```shell
matlab -batch 'STLextractToJSON("input.stl","output.json","RemoveOutlierRangeZ", false)'
```

If, on the other hand, you want to keep this behaviour, but want to specify another
threshold for the z-coordinate, you can do so by passing the `OutlierZThreshold` parameter:

```shell
matlab -batch 'STLextractToJSON("input.stl","output.json","OutlierZThreshold",0.1)'
```

If `"RemoveOutlierRangeZ"` is `false`, the `OutlierZThreshold` parameter is ignored.

To simulate similar behaviour in the $x$ and $y$ directions, you can use the
`"BoundingBoxLength"` parameter, which will remove all particles that have
any vertices outside the bounding box of the given length in the $x$ and $y$
directions. This assumes the packing is centered at the origin, and the bounding box
is symmetric around the origin. Example usage:

```shell
matlab -batch 'STLextractToJSON("input.stl","output.json","BoundingBoxLength",0.5)'
```

For instance, all particles that have any vertices with $x$ or $y$ coordinates
greater than 0.25 or less than -0.25 will be removed. A parameter of `NaN`
will disable this behavior, and all particles will be kept regardless of their
$x$ and $y$ coordinates.

You can also specify the `Cutoff` and `CutoffDirection` parameters, which will
extract an inner packing, but by specifying a margin percentage to remove,
instead of a fixed distance. For instance:

```shell
matlab -batch 'STLextractToJSON("input.stl","output.json","Cutoff",0.1,"CutoffDirection","y")'
```

This will remove all particles that have any vertices with $y$ coordinates that fall
outside of a bounding box of length 90% of the original packing in the $y$ direction.
This length will then be applied to the $x$ and $z$ directions as well.

If the `Cutoff` is 0, nothing is done.

## License

This project is licensed under the [MIT License](./LICENSE).
