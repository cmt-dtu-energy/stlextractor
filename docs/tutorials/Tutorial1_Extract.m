%% Tutorial: extracting the individual particles from an STL packing
% Suppose you are simulating some packing of particles. This could be used for
% fluid flow and heat transfer analysis in porous media, magnetic simulations
% of grains, some novel design and manufacturing technique etc.
%
% A possible workflow is to construct a _geometric_ model in a 3D software;
% we'll cite <https://www.blender.org/ Blender> because this is what is used in
% the test files in this project. This very tutorial contains such a file, |all_particles|,
% which consists of circa 200 hexagonal prisms of different sizes and shapes.
%
% *Note: currently, |STLExtractor| only supports extraction of hexagonal prisms.
% This could be extended in future releases.*
%% Setup: putting the package and the tutorial data on the MATLAB path
% Before running any of the cells below, MATLAB needs to be able to find two
% things:
%
% * the package itself (|STLExtractor.m|, |ExtractedPacking.m|, |HexagonalPrism.m|,
% |STLextractToJSON.m|, etc.), which lives at the root of the repository; and
% * the tutorial data used throughout this notebook, namely |all_particles.stl|,
% which lives alongside this file in |docs/tutorials|.
%
% If you already followed the "Installation" steps in the project's |README.md|
% (cloning the repository and adding its root folder to your MATLAB path), the
% package will already be visible and you can skip straight to running |which
% STLExtractor|. The cell below is defensive: it only adds folders to the path
% that are not already on it, so it is safe to run every time.

% Locate the folder this tutorial lives in, regardless of what the current
% MATLAB folder happens to be.
tutorialsDir = fileparts(which('Tutorial1_Extract'));

% The package itself lives two levels up from docs/tutorials, i.e. at the
% repository root.
packageDir = fileparts(fileparts(tutorialsDir));

if isempty(which('STLExtractor'))
    addpath(packageDir);
end

% Make sure the folder containing the tutorial data is also on the path (or,
% equivalently, you could just cd into docs/tutorials before running this).
addpath(tutorialsDir);

% Sanity check: this should now resolve to a file inside the repository root.
disp(which('STLExtractor'))
%%
% The main model for this package is called |STLExtractor|:

help STLExtractor
%%
% To actually instantiate one, you need the name of the STL file you want to
% process and a directory where you *could* save the individual extracted
% files. Note that passing a directory here is not enough by itself to make
% |STLExtractor| write anything to disk -- see the
% "Which files get written when saving is enabled" section near the end of
% this tutorial for the full explanation and the extra option you need to
% pass.

exampleFile = fullfile(tutorialsDir,"all_particles.stl");
outputDir = fullfile(tutorialsDir,"tmp");
% create folder if not existent
if ~isfolder(outputDir)
    mkdir(outputDir);
end

extractor = STLExtractor(exampleFile,outputDir);
%%
% Then, you call the |process| method:

l = extractor.process;
%% What |process| returns
% The returned object is an instance of |ExtractedPacking|, which represents
% exactly that: a _packing_ of _items_ that is _extracted_ from an STL file that
% contains the whole packing, originally without identification of said items.
%
% Let's take a look at what's inside this object. Notice that you get geometrical
% information and some descriptive statistics on the positions and orientations
% of the items.
%
% We use the term _alignment_ to indicate the dot product of an item's normal
% vector with one of the corresponding axes.

disp(l);
%%
% Where you can see it recognized almost 200 prisms, together with:
%
% * the bounding box of the whole packing (|xmin|/|xmax|, |ymin|/|ymax|,
% |zmin|/|zmax|, and the derived side lengths |Lx|, |Ly|, |Lz|);
% * the total |volume| of that bounding box, and the |volumetricFillingFraction|
% (how much of that box volume is actually occupied by hexagonal prisms); and
% * mean/standard-deviation alignment statistics along each axis, both
% unweighted and volume-weighted.
%
% You can also plot a rendering of the items:

l.plot
%% Filtering the packing while it is being extracted
% Besides the post-hoc cutoff procedures shown further below, |process| itself
% accepts three name-value options that filter out particles *before* the
% |ExtractedPacking| statistics (bounding box, alignments, etc.) are even
% computed:
%
% * |ZMinLimit| removes any particle that has at least one vertex with a
% z-coordinate below this absolute value;
% * |ZMaxLimit| removes any particle that has at least one vertex with a
% z-coordinate above this absolute value; and
% * |BoundingBoxLength| removes any particle that has at least one vertex
% outside of a square, centered on the origin, of this side length in the
% x- and y-directions (i.e. any vertex with |abs(x)| or |abs(y)| greater than
% |BoundingBoxLength/2|).
%
% Unlike the "Cutoff procedures" shown below, these three options take
% *absolute* coordinate values (in whatever units your STL file uses), not
% percentages of the packing's own size, and they apply while |process| is
% still building the |ExtractedPacking| object -- not afterwards.
%
% For instance, to only keep particles located in roughly the upper half of
% this packing:

zMidpoint = (l.zmin + l.zmax)/2;
lUpperHalf = extractor.process('ZMinLimit', zMidpoint);
fprintf("Kept %d of %d particles with ZMinLimit = %.3f\n", ...
    length(lUpperHalf), length(l), zMidpoint);
%%
% And to only keep particles inside a square column around the center of the
% packing:

boxLength = 0.6*min(l.Lx, l.Ly);
lBoxed = extractor.process('BoundingBoxLength', boxLength);
fprintf("Kept %d of %d particles with BoundingBoxLength = %.3f\n", ...
    length(lBoxed), length(l), boxLength);
%%
% |ZMinLimit|, |ZMaxLimit|, and |BoundingBoxLength| default to |NaN|, which
% disables the corresponding filter (all particles are kept in that
% direction). This is the same convention used by |STLextractToJSON|, covered
% later in this tutorial.
%% Cutoff procedures
% A major feature of |STLExtractor| is the ability to _cut off_ items from the
% raw extracted packing. There are three procedures currently implemented in |STLExtractor:|
%% Cutoff by vertices
% In this first version, you specify a margin and a direction. For instance,
% in the example below, you specify cut planes 5% off from the maximum and minimum
% coordinates of the packing (totaling a total 10% margin, which is what is passed
% to the function), and any items with any vertices beyond that cut plane are
% removed:

c1 = l.cutoff(0.1,"x","Method",CutoffMethod.vertices);
c1.plot;
%% Cutoff by centers
% By changing the |"Method"| argument, only items whose _center points_ surpass
% the cut planes are removed:

c2 = l.cutoff(0.1,"x","Method",CutoffMethod.centers);
c2.plot;
%% Cutoff in the z-direction only
% In a third method, you can cut the packing only in the z-direction. With this
% method, |STLExtractor| will calculate the averages of the lengths of the packing
% in the x and y direction, and then will try to extract a packing with this length
% in the middle of the z-direction:

c4 = l.cutoffz("Method",CutoffMethod.vertices);
c4.plot;
c5 = l.cutoffz("Method",CutoffMethod.centers);
c5.plot;
%% |STLextractToJSON| and command-line usage
% The cells above drive the |STLExtractor|/|ExtractedPacking| API interactively,
% which is convenient for exploration, but if you want to automate extraction
% (e.g. as part of a batch pipeline that doesn't open the MATLAB desktop at
% all), use the |STLextractToJSON| function instead:
%
%   STLextractToJSON(input, output)
%
% This reads the STL file |input|, runs it through the same |process| logic
% shown above (always with |ShouldSave| turned off -- see the next section),
% and serializes the resulting |ExtractedPacking| object as JSON into |output|.
%
% Let's try it on one of the smaller fixtures shipped with the test suite,
% |particles_48.stl| (a single flat layer of 48 hexagonal prisms):

jsonExampleFile = fullfile(packageDir,"tests","test_stl_files","particles_48.stl");
jsonOutputFile = fullfile(outputDir,"particles_48.json");
%%
% By default, |STLextractToJSON| does some post-processing: any particle with
% a vertex below the z = 0 plane is removed (this is the |RemoveOutlierRangeZ|
% / |OutlierZThreshold| pair of options, which map directly onto the
% |ZMinLimit| option of |process| discussed above). This particular fixture
% happens to lie *entirely* below z = 0, so running with the defaults removes
% every single particle and raises an error:

try
    STLextractToJSON(jsonExampleFile, jsonOutputFile);
catch runError
    fprintf("As expected, this failed: %s\n", runError.message);
end
%%
% To keep particles below z = 0, disable that default behavior with
% |"RemoveOutlierRangeZ", false|:

STLextractToJSON(jsonExampleFile, jsonOutputFile, "RemoveOutlierRangeZ", false);
jsonText = fileread(jsonOutputFile);
fprintf("Wrote %d characters of JSON to %s\n", numel(jsonText), jsonOutputFile);
disp(jsonText(1:200))
%%
% If, instead, you want to keep the default removal of particles below z = 0
% but move the threshold, use |OutlierZThreshold| (ignored when
% |RemoveOutlierRangeZ| is |false|):
%
%   STLextractToJSON(input, output, "OutlierZThreshold", 0.1)
%
% |BoundingBoxLength| behaves exactly as described in the "Filtering the
% packing" section above:

STLextractToJSON(jsonExampleFile, jsonOutputFile, ...
    "RemoveOutlierRangeZ", false, "BoundingBoxLength", 2.0);
%%
% Finally, |Cutoff| and |CutoffDirection| apply the same percentage-margin
% cutoff as the |cutoff| method shown earlier (always using
% |CutoffMethod.vertices|, since |STLextractToJSON| does not expose a way to
% choose |CutoffMethod.centers|). A |Cutoff| of 0 (the default) does nothing;
% otherwise it removes that fraction of the packing's extent from each side,
% starting from |CutoffDirection|, then applies the resulting length to the
% other two directions as well:

STLextractToJSON(jsonExampleFile, jsonOutputFile, ...
    "RemoveOutlierRangeZ", false, "Cutoff", 0.2, "CutoffDirection", "x");
%%
% All of the examples above can equally be run from a terminal, without
% starting the MATLAB desktop, using |matlab -batch| (after installing the
% package as described in |README.md|):
%
%   matlab -batch 'STLextractToJSON("particles_48.stl","particles_48.json","RemoveOutlierRangeZ", false)'
%
% and all the same name-value options apply, e.g.:
%
%   matlab -batch 'STLextractToJSON("particles_48.stl","particles_48.json","RemoveOutlierRangeZ",false,"Cutoff",0.2,"CutoffDirection","x")'
%
% The first argument must be an existing STL file, and the second must point
% into a writable (existing) directory; the file itself does not need to
% exist yet, it will be created.
%% Which files get written when saving is enabled
% So far, every call to |STLExtractor| in this tutorial has left |shouldSave|
% at its default of |false|, which means no individual per-particle STL files
% are ever written to |outputDir| -- it is accepted by the constructor, but
% otherwise unused until you opt in.
%
% To have |STLExtractor| write out one STL file per recognized particle, pass
% |"ShouldSave", true| to the constructor. We point it at a fresh
% sub-directory of |outputDir| here, purely so that the file count below is
% not mixed up with files from earlier cells in this tutorial:

savedParticlesDir = fullfile(outputDir,"saved_particles");
if ~isfolder(savedParticlesDir)
    mkdir(savedParticlesDir);
end
savingExtractor = STLExtractor(jsonExampleFile, savedParticlesDir, "ShouldSave", true);
%%
% Note that nothing is written to disk yet at this point -- construction only
% records the option. The files are written lazily, one at a time, as each
% particle is processed inside the |process| call:

lSaved = savingExtractor.process;

savedFiles = dir(fullfile(savedParticlesDir,"hexagon_*.stl"));
fprintf("process() wrote %d individual STL files to %s\n", ...
    numel(savedFiles), savedParticlesDir);
fprintf("first: %s, last: %s\n", savedFiles(1).name, savedFiles(end).name);
%%
% Each file is named |hexagon_NNNN.stl|, where |NNNN| is the particle's index
% (1-based, zero-padded to 4 digits, e.g. |hexagon_0001.stl|, |hexagon_0002.stl|,
% ...) in the order the particles were discovered while traversing the input
% STL file -- the same order used for |l.items| above. These are plain,
% self-contained STL files: each one can be opened independently in any STL
% viewer, or fed back into other MATLAB code as its own triangulation.
%
% Two things worth calling out explicitly:
%
% * saving happens *inside* |process|, not at construction time, and it
% happens for every particle found in the raw input file, before any of the
% |ZMinLimit|/|ZMaxLimit|/|BoundingBoxLength| filtering described above is
% applied -- so if you only want files for the particles that survive
% filtering, you currently need to filter the resulting |hexagon_*.stl| files
% yourself (e.g. by cross-referencing which indices remain in
% |lSaved.items|), since |process| does not skip writing a file for a particle
% it later discards.
% * |STLextractToJSON| always constructs its internal |STLExtractor| with
% |"ShouldSave", false| (see its source for the exact call). This means that
% running extraction from the command line, as shown in the previous section,
% *never* writes individual |hexagon_*.stl| files -- only the single JSON file
% you asked for. If you need both the aggregated JSON summary and the
% individual per-particle STL files, you must drive |STLExtractor| and
% |ExtractedPacking| directly as shown in this cell, rather than going through
% |STLextractToJSON|.
