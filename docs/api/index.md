# API Reference

This reference is generated from the MATLAB help text in the source files, so
it matches what `help <name>` and `doc <name>` show inside MATLAB.

## Main entry points

| Name | Kind | Purpose |
| --- | --- | --- |
| [`STLExtractor`](STLExtractor.md) | class | Reads an STL file and splits it into particles; `process` returns an `ExtractedPacking`. |
| [`ExtractedPacking`](ExtractedPacking.md) | class | The extracted packing: its prisms plus bounds, filling fraction and alignment statistics; plotting and filtering. |
| [`HexagonalPrism`](HexagonalPrism.md) | class | A single extracted particle and its geometric parameters; can be written to its own STL file. |
| [`STLextractToJSON`](STLextractToJSON.md) | function | One-call pipeline from an STL file to a JSON description of the packing, for command-line use. |

## Supporting types

[`CutoffMethod`, `CutoffProcedure`, `GeometricType`,
`HexagonalPrismTriangulation`, `PackingFigureRenderer`, `STLExtractorError`,
`vecnormalize` and `projectDir`](supporting.md) are used by, or returned from,
the main entry points.
