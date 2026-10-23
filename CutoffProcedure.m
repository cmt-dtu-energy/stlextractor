classdef CutoffProcedure
   %CUTOFFPROCEDURE Which margins of a packing to trim when extracting an inner one
   %   Enumerates the two cutoff strategies offered as separate public methods
   %   on EXTRACTEDPACKING: trimming every side (the 'sides' member mirrors
   %   EXTRACTEDPACKING.CUTOFF) or trimming only along z (the 'z' member
   %   mirrors EXTRACTEDPACKING.CUTOFFZ). This enumeration is not currently
   %   accepted as an argument by either method; it documents the two
   %   procedures conceptually and is reserved for a future API that lets
   %   callers select between them with a single name-value argument.
   %
   % See also EXTRACTEDPACKING/CUTOFF, EXTRACTEDPACKING/CUTOFFZ, CUTOFFMETHOD
   enumeration
      sides % Cutoff from all sides (x, y and z), as done by EXTRACTEDPACKING.CUTOFF
      z % Cutoff only in the z-direction, leaving x and y unchanged, as done by EXTRACTEDPACKING.CUTOFFZ
   end
end