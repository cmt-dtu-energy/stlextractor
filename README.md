# stlextractor - version 0.14.0


MATLAB package to process a large STL file containing a packing of multiple hexagonal 
prisms (the only supported form at the moment) and parse each prism, 
identifying its geometric parameters such as radius, axis, volume etc.

Each individual prism can then be imported to its own STL file, or have their info
available to other MATLAB programs.

Motivation: we want to simulate packing of particles, but want to assign different
properties to each prism. With `STLExtractor`, we can generate the packing
in a geometric modeling software, and have the library parse this purely geometric info;
the individual objects can then be part of a MATLAB project that recognizes the orientation, radius
or thickness as parameters for some other property (e.g. having all particles of given radius
have a certain mechanical strength). Alternatively, you can just use the project
to save the individual STL files and import them into a simulation software, manually setting
up different parameters.

## Installation

- Clone this repo to a location of choice;
- Add the folder to the MATLAB path

## Usage

See an example [Live Script](./docs/tutorials/Tutorial1_Extract.mlx) for examples of using
the package (you need to add the [tutorials](./docs/tutorials/) folder to the MATLAB
path for it to run correctly, or to change the current folder to this path).

The API is class-based. Check out the documentation for the `STLExtractor` class,
which is the main entry-point for reading an STL file. The result of actually
parsing and processing the file is an instance of `ExtractedPacking`.

## Testing

- Run `runtests("tests")` in the MATLAB Command Window to run the test suite.
- Run `coverage` in the MATLAB Command Window to run the tests and open a test coverage report
- See [docs/known-untested.md](docs/known-untested.md) for the branches the suite deliberately does not cover


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
you can use the `STLextractToJSON(input,output)`, which will:

- read a STL file `input`;
- process it;
- serialize the information about the extracted particles in `output`

The intended usage is to run from the command line (after installting the package
according to the instructions above).  In the simplest case, to just read a STL file
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

You can also specify the `cutoff` and `cutoffDirection` parameters, which will
extract an inner packing, but by specifying a margin percentage to remove,
instead of a fixed distance. For instance:

```shell
matlab -batch 'STLextractToJSON("input.stl","output.json","Cutoff",0.1,"CutoffDirection","y")'
```

This will remove all particles that have any vertices with $y$ coordinates that faill
outside of a bounding box of length 90% of the original packing in the $y$ direction.
This length will then be applied to the $x$ and $z$ directions as well.

If the `Cutoff` is 0, nothing is done.
