classdef CutoffMethod
    %CUTOFFMETHOD Method used to decide which items are removed by a cutoff
    %   Passed as the 'Method' name-value argument to EXTRACTEDPACKING.CUTOFF
    %   and EXTRACTEDPACKING.CUTOFFZ to control how particles near a cut plane
    %   are selected for removal.
    %
    % See also EXTRACTEDPACKING/CUTOFF, EXTRACTEDPACKING/CUTOFFZ
   enumeration
      vertices % An item is removed if ANY of its vertices lies beyond the cut plane (stricter: trims partially-cut particles too)
      centers % An item is removed only if its center lies beyond the cut plane (keeps particles that are merely clipped)
   end
end