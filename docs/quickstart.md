# Quickstart

This page gets you from a fresh clone to an extracted, plotted packing in a
single copy-paste. Make sure you have followed the
[Installation](installation.md) steps first (or keep the `addpath` line
below, pointing it at your clone).

## Extract a packing

--8<-- "README.md:quickstart"

Expected output:

```text
Extracted 48 particles
First particle: radius = 0.375, thickness = 0.375
Filling fraction: 0.280
```

and a figure like this:

![The 48-particle fixture rendered by ExtractedPacking.plot](assets/quickstart-packing.png){ width="560" }

## What you just got

- `extractor` is an [`STLExtractor`](api/STLExtractor.md). `"ShouldSave",
  false` tells it not to write any files; pass a folder as the second argument
  and `"ShouldSave", true` to write one STL file per particle.
- `packing` is an [`ExtractedPacking`](api/ExtractedPacking.md): its `items`
  are [`HexagonalPrism`](api/HexagonalPrism.md) objects, and it also exposes
  the bounding box (`xmin` … `zmax`, `Lx`, `Ly`, `Lz`), the
  `volumetricFillingFraction` and alignment statistics.
- `packing.plot()` renders all prisms, colouring them consistently by type.

## Keep only part of the packing

```matlab
% keep only particles inside a 4 x 4 square column around the origin
boxed = extractor.process("BoundingBoxLength", 4);

% or trim 10% of the side length from every side of the packing
trimmed = packing.cutoff(0.1, "x");
fprintf("%d -> %d (boxed), %d (trimmed) particles\n", ...
    length(packing), length(boxed), length(trimmed));
```

## From the command line

`STLextractToJSON` wraps the whole pipeline for non-interactive use:

```shell
matlab -batch 'addpath("/path/to/stlextractor"); STLextractToJSON("input.stl", "output.json")'
```

See [`STLextractToJSON`](api/STLextractToJSON.md) for its filtering options.

## Next

The [Tutorial](tutorial.md) walks through a larger packing, all the filtering
options, which files get written when saving is enabled, and JSON export.
