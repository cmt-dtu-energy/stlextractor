classdef HexagonalPrism
  %HEXAGONALPRISM A single prism with two regular-hexagon faces
  %   A HexagonalPrism is the geometric representation of one particle in a
  %   packing: a right prism whose top and bottom faces are regular hexagons,
  %   described by its center position, hexagon radius, thickness (axial
  %   height) and the orientation of its main axis. Instances are normally
  %   produced by STLEXTRACTOR.PROCESS, one per particle found in an STL file.
  %
  % See also STLEXTRACTOR, EXTRACTEDPACKING, HEXAGONALPRISMTRIANGULATION

  properties (SetAccess = immutable)
    thickness (1,1) double % Axial height of the prism, i.e. the distance between its two hexagonal faces
    volume (1,1) double % Prism volume: area * thickness
    position (1,3) double  % [x,y,z] coordinates of the prism's center
    radius (1,1) double % Circumradius of the hexagonal cross-section (center to vertex distance)
    normal (1,3) double % Unit vector along the prism's main axis (perpendicular to the hexagonal faces)
    area (1,1) double % Area of one hexagonal face: (3*sqrt(3)/2) * radius^2
    faceRotation(1,3) double % Unit vector giving the in-plane rotation of the hexagonal face about 'normal' (orientation of one hexagon vertex)
    vertices (12,3) double % The 12 vertex coordinates of the prism (6 per hexagonal face), as rows
    triangulation % Triangulation of the prism's surface (a MATLAB triangulation, or a HEXAGONALPRISMTRIANGULATION); see WRITE
  end

  methods
      function obj = HexagonalPrism(position,radius,thickness,normal,faceRotation,triangulation)
      %HEXAGONALPRISM Construct a hexagonal prism from its geometric parameters
      %
      %   hp = HEXAGONALPRISM(position,radius,thickness,normal) builds a prism
      %       centered at 'position', with the given hexagon 'radius' and axial
      %       'thickness', whose main axis points along 'normal' (it need not
      %       be a unit vector; it is normalized internally). A default
      %       triangulation is generated via HEXAGONALPRISMTRIANGULATION.
      %
      %   hp = HEXAGONALPRISM(position,radius,thickness,normal,faceRotation)
      %       additionally sets the in-plane orientation of the hexagonal
      %       faces.
      %
      %   hp = HEXAGONALPRISM(position,radius,thickness,normal,faceRotation,triangulation)
      %       uses the supplied triangulation (e.g. extracted from an STL
      %       file by STLEXTRACTOR) instead of generating one.
      %
      % See also HEXAGONALPRISMTRIANGULATION

      arguments
        position (1,3) double
        radius (1,1) double {mustBePositive}
        thickness (1,1) double {mustBePositive}
        normal  (1,3) double
        faceRotation (1,3) double = [1,0,0]
        triangulation = []
      end

      obj.thickness = thickness;
      obj.radius = radius;
      obj.position = position;
      STLExtractorError.mustBeNonZeroNorm(normal, "normal");
      obj.normal = normal./norm(normal);
      obj.area = 3/2*sqrt(3)*obj.radius^2;
      STLExtractorError.mustBeNonZeroNorm(faceRotation, "faceRotation");
      obj.faceRotation = faceRotation ./ norm(faceRotation);
      obj.volume = obj.area * obj.thickness;

      if isempty(triangulation)
          triangulation = HexagonalPrismTriangulation(position,radius,thickness,obj.normal);
      end

      STLExtractorError.mustBeValidTriangulation(triangulation, "HexagonalPrism constructor");
      obj.triangulation = triangulation;
      obj.vertices = obj.triangulation.Points;
    end

    function write(obj,filename)
      %WRITE Write the object triangulation to the filename STL file.

      % obj.triangulation may be a HexagonalPrismTriangulation, which only
      % fakes isa(...,'triangulation') and does not implement methods like
      % faceNormal that stlwrite calls on it. Wrap Points/ConnectivityList
      % in a real triangulation so stlwrite's internals resolve correctly
      % regardless of which strategy produced them (issue #26).
      TR = triangulation(obj.triangulation.ConnectivityList, obj.triangulation.Points);
      stlwrite(TR,filename)
    end
  end
end

