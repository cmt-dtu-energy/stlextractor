function out = vecnormalize(in)
    %VECNORMALIZE Return a unit vector with the same orientation as 'in'
    %
    %   out = VECNORMALIZE(in) divides 'in' by its own norm, so that
    %       norm(out) == 1 and out points in the same direction as 'in'.
    %       Throws an STLExtractor:Validation:NullVector error (via
    %       STLExtractorError.mustBeNonZeroNorm) if 'in' has zero norm.
    %
    % Example:
    %   v = vecnormalize([3,4,0]); % v == [0.6, 0.8, 0]
    arguments
        in (1,:) double {mustBeFinite}
    end
    STLExtractorError.mustBeNonZeroNorm(in, "input vector");
    out = in ./ norm(in);
end