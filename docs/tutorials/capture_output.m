% CAPTURE_OUTPUT Run Tutorial1_Extract.m cell-by-cell and record real output.
%
% Splits Tutorial1_Extract.m into cells using the same rule as
% docs/hooks/livescript.py's _split_cells (a line starting with "%%" begins
% a new cell), then runs each cell in its OWN `matlab -batch` process (see
% capture_one_cell.m), chaining variables between cells through saved .mat
% checkpoints rather than a single shared session.
%
% A single shared session was tried first and reliably hung partway
% through -- specifically on the "Cutoff in the z-direction only" cell,
% which creates two figures, after twelve prior diary-on/diary-off and
% figure-creation cycles in the same process. The exact cause was not
% pinned down (that same cell runs fine on its own, in a fresh session);
% isolating every cell into its own process sidesteps whatever state
% accumulates, at the cost of ~N extra MATLAB startups.
%
% Output: captured_entries/cell_NNN.json (one per cell, {index, output,
% figures}) and captured_figures/cell_NNN_K.png for the K-th new figure of
% cell NNN. docs/hooks/livescript.py reads both back in to interleave real
% output into the rendered Tutorial page.

thisDir = fileparts(which('capture_output'));
cd(thisDir);

sourceFile = fullfile(thisDir, "Tutorial1_Extract.m");
figuresDir = fullfile(thisDir, "captured_figures");
entriesDir = fullfile(thisDir, "captured_entries");
stateDir = fullfile(tempdir, "stlextractor_capture_state");

for d = [figuresDir, entriesDir, stateDir]
    if isfolder(d)
        rmdir(d, 's');
    end
    mkdir(d);
end

lines = strsplit(string(fileread(sourceFile)), {'\r\n', '\n'});
cellLines = {};
for iLine = 1:numel(lines)
    line = lines(iLine);
    if startsWith(line, "%%")
        cellLines{end+1} = string([]); %#ok<AGROW>
    elseif isempty(cellLines)
        cellLines{end+1} = line; %#ok<AGROW>
    else
        cellLines{end} = [cellLines{end}, line];
    end
end
nCells = numel(cellLines);

matlabExe = fullfile(matlabroot, "bin", "matlab");

for iCell = 0:nCells-1
    fprintf("[capture_output] cell %d/%d (own process)\n", iCell, nCells - 1);
    if iCell == 0
        stateIn = "";
    else
        stateIn = fullfile(stateDir, sprintf("state_%03d.mat", iCell - 1));
    end
    stateOut = fullfile(stateDir, sprintf("state_%03d.mat", iCell));

    expr = sprintf( ...
        "capture_one_cell('%s', %d, '%s', '%s', '%s', '%s')", ...
        sourceFile, iCell, stateIn, stateOut, figuresDir, entriesDir);
    cmd = sprintf('"%s" -batch "%s"', matlabExe, expr);
    status = system(cmd);
    if status ~= 0
        error("capture_output:cellFailed", "Cell %d failed (exit status %d)", iCell, status);
    end
end

fprintf("Captured output for %d cells into %s and %s\n", nCells, entriesDir, figuresDir);
