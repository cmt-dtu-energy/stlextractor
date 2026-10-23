classdef HexagonalPrismTriangulation
    %HEXAGONALPRISMTRIANGULATION Strategy for creating a simple triangulation for
    % a prism from its geometric information

    properties
        Points (12,3) double
        ConnectivityList (20,3) double
    end


    methods
        function obj = HexagonalPrismTriangulation(position,radius,thickness,normal)
            %HEXAGONALPRISMTRIANGULATION Construct an instance of this class
            arguments
                position (1,3) double
                radius (1,1) double {mustBePositive}
                thickness (1,1) double {mustBePositive}
                normal  (1,3) double {mustBeNormalized}
            end

            position = position(:)';  % Ensure row vector
            normal = normal(:)' / norm(normal);  % Normalize and ensure row vector

            % Create local coordinate system
            % Find two orthogonal vectors perpendicular to normal
            if abs(normal(3)) < 0.9
                u = cross(normal, [0, 0, 1]);
            else
                u = cross(normal, [1, 0, 0]);
            end
            u = u / norm(u);
            v = cross(normal, u);

            % Generate hexagon vertices in local 2D coordinates
            angles = (0:5) * pi/3;  % 60-degree increments
            hexU = radius * cos(angles);
            hexV = radius * sin(angles);



            % Transform hexagon to 3D space
            hex3D = zeros(6, 3);
            for i = 1:6
                hex3D(i, :) = hexU(i) * u + hexV(i) * v;
            end

            % Create vertices for both faces
            offset = (thickness / 2) * normal;
            topFace = hex3D + offset + position;
            bottomFace = hex3D - offset + position;

            % Combine all vertices
            obj.Points = [bottomFace; topFace];  % 12 vertices total
            % Define triangular faces
            faces = [];

            % Bottom face triangles (vertices 1-6): 3 "ear" triangles plus
            % one center triangle over the alternating vertices, using only
            % skip-one diagonals. A single-vertex fan would instead use the
            % long diagonal (e.g. 1-4), which in a regular hexagon is
            % parallel to two of the hexagon's own edges and spuriously
            % collides with STLExtractor's axial-edge detection (issue #26).
            faces = [faces; 5, 6, 1];
            faces = [faces; 1, 2, 3];
            faces = [faces; 3, 4, 5];
            faces = [faces; 1, 3, 5];

            % Side faces (rectangular faces split into triangles)
            for i = 1:6
                next_i = mod(i, 6) + 1;

                % Bottom vertex indices
                v1 = i;
                v2 = next_i;

                % Top vertex indices
                v3 = i + 6;
                v4 = next_i + 6;

                % Two triangles per rectangular face
                faces = [faces; v1,  v3,v4];  % First triangle
                faces = [faces; v1, v4, v2];  % Second triangle
            end

            % Top face triangles (vertices 7-12): mirrored winding relative
            % to the bottom cap so face orientation stays consistent.
            faces = [faces; 7, 8, 9];
            faces = [faces; 9, 10, 11];
            faces = [faces; 11, 12, 7];
            faces = [faces; 7, 9, 11];

            obj.ConnectivityList = faces;


        end

        % Override isa to return true for triangulation
        function tf = isa(obj, className)
            if strcmp(className, 'triangulation')
                tf = true;
            else
                tf = builtin('isa', obj, className);
            end
        end

    end
end