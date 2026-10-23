function STLextractToJSON(input, output, options)
%STLEXTRACTTOJSON Extract a packing from an STL file and write it to a JSON file
%
%   STLEXTRACTTOJSON(input, output) reads the STL file 'input', extracts its
%       packing of hexagonal prisms via STLEXTRACTOR, and writes the resulting
%       EXTRACTEDPACKING as JSON (via jsonencode) to the file 'output'.
%
%   STLEXTRACTTOJSON(input, output, 'RemoveOutlierRangeZ', tf) controls whether
%       particles below 'OutlierZThreshold' are discarded before encoding.
%       Default: true.
%
%   STLEXTRACTTOJSON(input, output, 'OutlierZThreshold', z) sets the z-position
%       threshold used above. Default: 0.0.
%
%   STLEXTRACTTOJSON(input, output, 'Cutoff', margin, 'CutoffDirection', dir)
%       additionally trims the extracted packing with EXTRACTEDPACKING.CUTOFF,
%       removing a fraction 'margin' of the side length starting from direction
%       'dir' ("x", "y" or "z"). Default margin: 0.0 (no cutoff).
%
%   STLEXTRACTTOJSON(input, output, 'BoundingBoxLength', L) discards particles
%       outside a square of side L (in x and y) centered at the origin.
%
% Example:
%   STLextractToJSON("packing.stl", "packing.json", "Cutoff", 0.1);
%
% See also STLEXTRACTOR, EXTRACTEDPACKING
arguments
    input (1,1) string
    output (1,1) string
    options.RemoveOutlierRangeZ (1,1) logical = true
    options.OutlierZThreshold (1,1) double = 0.0
    options.Cutoff (1,1) double {mustBeNonnegative} = 0.0
    options.CutoffDirection (1,1) string  = "x"
    options.BoundingBoxLength (1,1) double = NaN
end

try
    % Validate input file
    STLExtractorError.mustBeFile(input, "STLextractToJSON input");
    % Validate output directory
    outDir = fileparts(output);
    if outDir ~= ""
        STLExtractorError.mustBeFolder(outDir, "STLextractToJSON output directory");
    end
    % Validate cutoff direction
    STLExtractorError.mustBeValidDirection(options.CutoffDirection);

    if options.RemoveOutlierRangeZ
        zMinLimit = options.OutlierZThreshold;
    else
        zMinLimit = NaN;
    end

    e = STLExtractor(input,[],"ShouldSave",false);
    ep = e.process( ...
        'ZMinLimit', zMinLimit, ...
        'BoundingBoxLength', options.BoundingBoxLength);
    if options.Cutoff > 0
        ep = ep.cutoff(options.Cutoff,options.CutoffDirection);
    end

    jsonOutput = jsonencode(ep);

    f = fopen(output,"w");
    if f == -1
        STLExtractorError.throwError("STLextractToJSON", "FileOpenFailed", "Could not open output file for writing.");
    end
    fprintf(f,"%s",jsonOutput);
    fclose(f);
catch ME
    % Rethrow as STLExtractorError if not already
    if ~startsWith(ME.identifier, "STLExtractor:")
        STLExtractorError.throwError("STLextractToJSON", "UnhandledError", ME.message);
    else
        rethrow(ME);
    end
end
end
