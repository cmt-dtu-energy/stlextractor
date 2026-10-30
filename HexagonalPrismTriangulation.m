classdef HexagonalPrismTriangulation
    %HEXAGONALPRISMTRIANGULATION Generate a triangulated hexagonal prism mesh
    %   This class builds the 12 vertices and 20 triangular faces of a
    %   hexagonal prism (two hexagonal caps plus six rectangular side faces,
    %   each split into two triangles) directly from its geometric parameters,
    %   without needing an existing mesh to read from. It mimics the public
    %   interface of MATLAB's built-in 'triangulation' (Points and
    %   ConnectivityList, plus an ISA override) so it can be used wherever a
    %   triangulation is expected, e.g. as the default triangulation of a
    %   HEXAGONALPRISM. It is rebuilt as a proper 'triangulation' object before
    %   being passed to functions like stlwrite that need the full interface
    %   (see HEXAGONALPRISM.WRITE).
    %
    % See also HEXAGONALPRISM

    properties
        Points (12,3) double % 12 vertex coordinates: rows 1-6 are the bottom hexagonal face, rows 7-12 the top face
        ConnectivityList (20,3) double % 20 triangular faces, each row listing the 3 vertex indices (into Points) of one triangle
    end


    methods
        function obj = HexagonalPrismTriangulation(position,radius,thickness,normal)
            %HEXAGONALPRISMTRIANGULATION Build a prism mesh from its geometry
            %
            %   t = HEXAGONALPRISMTRIANGULATION(position,radius,thickness,normal)
            %       constructs the 12-vertex, 20-triangle mesh of a hexagonal
            %       prism centered at 'position', with hexagon 'radius',
            %       axial 'thickness', and main axis along the unit vector
            %       'normal'.
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

        function tf = isa(obj, className)
            % ISA Override so this class reports as a 'triangulation' too.
            %   Lets code (and argument validators) that only check
            %   isa(x,'triangulation') accept this lightweight stand-in; it
            %   does NOT implement the rest of the triangulation interface
            %   (e.g. faceNormal), so callers that need that must first
            %   convert via triangulation(obj.ConnectivityList, obj.Points).
            if strcmp(className, 'triangulation')
                tf = true;
            else
                tf = builtin('isa', obj, className);
            end
        end

    end
end