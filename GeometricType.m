classdef GeometricType < handle
    %GEOMETRICTYPE Rotation- and position-independent geometric type of a prism
    %   Two HEXAGONALPRISM objects are considered to be of the "same type" if
    %   their hexagon radius and axial height match (within a tolerance),
    %   regardless of where they are located or how they are oriented. This
    %   class captures just that (radius, height) pair plus the EQ comparison,
    %   and is used internally by STLEXTRACTOR to group particles by type.
    %
    % See also HEXAGONALPRISM

    properties
        radius % Hexagon circumradius of the prism type
        height % Axial height (thickness) of the prism type
        tol = 1e-3; % Relative tolerance used by EQ when comparing radius and height
    end

    methods
        function obj = GeometricType(radius, height)
            %GEOMETRICTYPE Construct a geometric type from a radius and height

            obj.radius = radius;
            obj.height = height;
        end

        function is_eq = eq(obj,other)
            %EQ Compare equality of two instances of GEOMETRICTYPE
            %   Two instances are considered equal if their radii
            %   and their heights are approximately equal, withing
            %   the absolute tolerance given by the 'tol' property
            is_eq_radius = abs(1-obj.radius/other.radius) < obj.tol;
            is_eq_height = abs(1-obj.height/other.height) < obj.tol;
            is_eq = is_eq_radius && is_eq_height;
        end
    end
end