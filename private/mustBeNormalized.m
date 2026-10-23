function mustBeNormalized(v)
% MUSTBENORMALIZED Argument validator: errors unless norm(v) is within 1e-4 of 1
tol = 1e-4;
if abs(norm(v,2)-1.0) >= tol
  error("Vector must be normalized")
end
end