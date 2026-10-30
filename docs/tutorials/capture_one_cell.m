function capture_one_cell(capture_source, capture_index, capture_stateIn, capture_stateOut, capture_figuresDir, capture_entriesDir)
%CAPTURE_ONE_CELL Execute a single tutorial %% cell in its own MATLAB process.
%
% Called once per cell by capture_output.m, each invocation in a fresh
% `matlab -batch` process, because running every cell within one shared
% session was observed to reliably hang partway through (on the cell that
% creates two figures, after several prior diary/figure cycles in the same
% session -- cause not pinned down). A fresh process per cell avoids
% whatever accumulated state triggers that. Workspace state between cells
% is carried through a saved/loaded .mat checkpoint rather than a shared
% session.
%
% All of this function's own bookkeeping variables are named with a
% "capture_" prefix and excluded by name before saving state, so only
% variables the tutorial itself defines (loaded from the previous
% checkpoint, plus whatever this cell's code newly assigns) get persisted
% for the next cell.

capture_thisDir = fileparts(which('capture_one_cell'));
addpath(fileparts(fileparts(capture_thisDir))); % the package itself
addpath(capture_thisDir); % all_particles.stl etc.

if ~isfolder(capture_figuresDir)
    mkdir(capture_figuresDir);
end
if ~isfolder(capture_entriesDir)
    mkdir(capture_entriesDir);
end

if ~isempty(capture_stateIn) && isfile(capture_stateIn)
    load(capture_stateIn);
end

capture_lines = strsplit(string(fileread(capture_source)), {'\r\n', '\n'});
capture_cellLines = {};
for capture_iLine = 1:numel(capture_lines)
    capture_line = capture_lines(capture_iLine);
    if startsWith(capture_line, "%%")
        capture_cellLines{end+1} = string([]); %#ok<AGROW>
    elseif isempty(capture_cellLines)
        capture_cellLines{end+1} = capture_line; %#ok<AGROW>
    else
        capture_cellLines{end} = [capture_cellLines{end}, capture_line];
    end
end

capture_code = strjoin(capture_cellLines{capture_index + 1}, newline);

capture_diaryFile = [tempname(), '.txt'];
capture_before = findobj(groot, 'Type', 'figure');
diary(capture_diaryFile);
diary on;
eval(capture_code);
diary off;
if isfile(capture_diaryFile)
    capture_output = string(fileread(capture_diaryFile));
    delete(capture_diaryFile);
else
    capture_output = "";
end
capture_after = findobj(groot, 'Type', 'figure');
capture_newFigs = setdiff(capture_after, capture_before);
if ~isempty(capture_newFigs)
    [~, capture_order] = sort(arrayfun(@(f) f.Number, capture_newFigs));
    capture_newFigs = capture_newFigs(capture_order);
end

% A cell array, not a string array: jsonencode always writes a cell array
% as a JSON list, even with 0 or 1 elements, whereas a 1-element string
% array collapses to a bare JSON string instead of a 1-element list.
capture_figureFiles = cell(1, numel(capture_newFigs));
for capture_k = 1:numel(capture_newFigs)
    capture_figureFiles{capture_k} = sprintf("cell_%03d_%d.png", capture_index, capture_k);
    saveas(capture_newFigs(capture_k), fullfile(capture_figuresDir, capture_figureFiles{capture_k}));
    close(capture_newFigs(capture_k));
end

capture_entry = struct();
capture_entry.index = capture_index;
capture_entry.output = capture_output;
capture_entry.figures = capture_figureFiles;
capture_jsonText = jsonencode(capture_entry, "PrettyPrint", true);
capture_entryFile = fullfile(capture_entriesDir, sprintf("cell_%03d.json", capture_index));
capture_fid = fopen(capture_entryFile, "w");
fwrite(capture_fid, capture_jsonText);
fclose(capture_fid);

% Persist only the tutorial's own variables (loaded state plus whatever
% this cell's code newly assigned) -- everything with a "capture_"
% prefix is this function's own bookkeeping, not tutorial state.
capture_allVars = who;
capture_keep = capture_allVars(~startsWith(capture_allVars, "capture_"));
if ~isempty(capture_stateOut) && ~isempty(capture_keep)
    save(capture_stateOut, capture_keep{:});
end
end
