function p = projectDir
    %PROJECTDIR Return the absolute path to the folder containing this file
    %
    %   p = PROJECTDIR() returns the folder this function lives in, i.e. the
    %       STLExtractor package root, regardless of the caller's current
    %       folder. Useful for building paths to files shipped with the
    %       package (e.g. test fixtures, resources).
    [p,~,~] = fileparts(mfilename("fullpath"));
end