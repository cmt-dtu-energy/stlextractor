classdef HexagonalPrism
  %HEXAGONALPRISM Representation of a prism with two hexagonal faces

  properties (SetAccess = immutable)
    thickness (1,1) double
    volume (1,1) double
    position (1,3) double 
    radius (1,1) double
    normal (1,3) double
    area (1,1) double
    faceRotation(1,3) double
    vertices (12,3) double
    triangulation
  end

  methods
      function obj = HexagonalPrism(position,radius,thickness,normal,faceRotation,triangulation)
      arguments
        position (1,3) double
        radius (1,1) double {mustBePositive}
        thickness (1,1) double {mustBePositive}
        normal  (1,3) double
        faceRotation (1,3) double = [1,0,0]
        triangulation = []
      end
      %HEXAGONALPRISM Construct an instance of this class

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

