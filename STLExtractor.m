classdef STLExtractor < handle
  %STLEXTRACTOR Extract individual hexagonal prisms from a packed STL file
  %   Objects of this class process an STL file that contains a packing of many
  %   hexagonal prisms glued together into a single mesh, and split it back into
  %   individual "particles". This is the main entry point of the STLExtractor
  %   package: construct an instance with a filename, then call PROCESS to obtain
  %   an EXTRACTEDPACKING with one HEXAGONALPRISM per particle found in the file.
  %
  %   e = STLEXTRACTOR(filename, saveDir) creates an extractor for the STL file
  %      named 'filename'.
  %   ep = e.process() runs the extraction and returns the resulting ExtractedPacking.
  %
  % Example:
  %   e = STLExtractor("packing.stl", pwd);
  %   ep = e.process();
  %
  % See also EXTRACTEDPACKING, HEXAGONALPRISM, STLEXTRACTTOJSON


  properties (SetAccess = private)
    baseFilename string {mustBeFile} % Path to the input STL file that will be parsed
    saveDir string {mustBeFolder} % Folder where individual particle STL files are written when ShouldSave is true
    shouldSave (1,1) logical % Whether PROCESS should also write each extracted particle to its own STL file in saveDir
  end



  properties (Access = private)
    nParticles % number of individual particles recognized from the input STL file
    pointsInParticle    % vector of particle indexes; the i-th element is the particle
    % index of the i-th point extracted from the input STL file
    globalTriangulation % global triangulation objected extracted from the input STL
    % This object has the following fields:
    %   - Points: a matrix where each row is the coordinate
    %       vector of a vertex
    %   - ConnectivityList: a matrix where:
    %       - Each element is a vertex ID;
    %       - Each row represents a triangle or tetrahedron in the
    %         triangulation;
    %       - Row numbers of are a triangle or tetrahedron IDs
    particleTypes
    particleGeometry
  end

  methods
    function obj = STLExtractor(filename,saveDir,options)
      %STLEXTRACTOR Construct an extractor that processes a STL file and partitions
      %     it into individual particle meshes.
      %
      % ex = STLEXTRACTOR(filename,saveDir) will instantiate an extractor
      %     based on the STL file named 'filename'. If 'ShouldSave' is true,
      %     individual STL files for each extracted hexagonal prism are written
      %     into 'saveDir'; otherwise 'saveDir' may be left empty ([]).
      %
      % ex = STLEXTRACTOR(filename,saveDir,'ShouldSave',true) also writes each
      %     extracted particle to its own STL file in 'saveDir'.
      %
      % See also HEXAGONALPRISM, EXTRACTEDPACKING
      arguments
        filename
        saveDir
        options.ShouldSave (1,1) logical = false
      end

      obj.baseFilename = filename;
      obj.saveDir = saveDir;

      obj.shouldSave = options.ShouldSave;

    end

    function ep = process(obj,options)
      %PROCESS Run the extraction process and return the extracted particles
      %
      % ep = PROCESS(obj) reads obj.baseFilename, separates its mesh into
      %    individual hexagonal prisms, and returns the result as an
      %    EXTRACTEDPACKING.
      %
      % ep = PROCESS(obj,'BoundingBoxLength',L) additionally discards any
      %    particle whose center falls outside a square of side L centered
      %    at the origin, in both x and y.
      %
      % ep = PROCESS(obj,'ZMinLimit',zmin) / PROCESS(obj,'ZMaxLimit',zmax)
      %    additionally discard particles below zmin, or above zmax,
      %    respectively.
      %
      % See also EXTRACTEDPACKING
      arguments
        obj STLExtractor
        options.BoundingBoxLength (1,1) double = NaN % Maximum length of the packing in both the x- and y-directions; will eliminate any particles with abs(x) (or abs(y)) >= +/- BoundingBoxLength/2
        options.ZMinLimit (1,1) double = NaN % Minimum limit of z-position to include particles (will eliminate particles below this position
        options.ZMaxLimit (1,1) double = NaN % Maximum limit of z-position to include particles (will eliminate particles above this position
      end

      [Packing,geometricInfo] = obj.AnalyzeSTL;

      l = HexagonalPrism.empty;


      for iParticle = 1:obj.nParticles
        position = geometricInfo(iParticle).center;
        radius = Packing.AllTheRadii(iParticle);
        thickness = Packing.AllTheHeights(iParticle);
        normal = geometricInfo(iParticle).axes;
        faceRotation = Packing.AllTheAxes2{iParticle};
        triangulation = geometricInfo(iParticle).TR;
        l(iParticle) = HexagonalPrism(position, radius, thickness,normal,faceRotation,triangulation);

      end

      opts = namedargs2cell(options);
      ep = ExtractedPacking(l, opts{:});


    end
  end

  methods (Access = private)


    function [Packing,geometricInfo] = AnalyzeSTL(obj)
      % ANALYZESTL Process the STL file to calculate geometric parameters and
      %   produce individual files.

      obj.globalTriangulation = stlread(obj.baseFilename) ;

      obj.extractIndividualParticles;

      [Packing,geometricInfo] = obj.processParticles;

    end

    function extractIndividualParticles(obj)
      % EXTRACTINDIVIDUALPARTICLES Separate all triangles into connected ones
      %
      %   [particles, n_actual_particles] = EXTRACTINDIVIDUALPARTICLES(TR) will
      %      load a triangulation object TR and divide the contained triangles into individual
      %      "particles" that contain connected triangles.
      %      The returned particles is a vector with the IDs of "groups" of triangles.

      A = obj.createConnectivityMatrix;

      % correct cases where the order of edges are incorrect between
      % adjacent triangles
      A = A + A.';
      A = A ~= 0;

      G = graph(A) ;
      obj.pointsInParticle = conncomp(G) ;

      obj.nParticles = max(obj.pointsInParticle);
      obj.particleTypes = ones(1,obj.nParticles);
      obj.particleGeometry = GeometricType.empty;
    end

    function A = createConnectivityMatrix(obj)
      % CREATECONNECTIVITYMATRIX Parse triangulation matrix and connect the dots.
      %

      %      The A matrix has 1 in the (i,j) position if there is an edge between
      %         points whose IDS are i and j, and 0 otherwise.


      n_points = size(obj.globalTriangulation.Points,1) ; % points
      C = obj.globalTriangulation.ConnectivityList;
      n_triangles = size(C,1) ; % triangles

      % C is a matrix like 
      %
      % [v1 v2 v3;
      %  v4 v5 v6]
      %
      % where the vi are vertices IDs
      % and we want to say that points v1-v2 are connected, v2-v3 are connected, and
      % the same for v3-v1, v4-v5, v5-v6, v6-v1
      % so:
      % A(v1,v2) = 1
      % A(v2,v3) = 1
      % A(v3,v1) = 1
      % and similarly for every row (i.e. each triangle)
      %
      % to contruct a sparse matrix with this pattern, we gather the rows in order:
      i = C';
      i = i(:);

      % and do the same here, but placing the first column last
      j = C(:,[2,3,1]);
      j = j';
      j = j(:);

      v = ones([3*n_triangles,1]);

      % this construction means that A(i(k),j(k)) = v(k), and the final matrix is
      % n_points by n_points
      A = sparse(i,j,v,n_points,n_points);
    end

    function [Packing,geometricInfo] = processParticles(obj)
      % PROCESSPARTICLES Fit geometric parameters for every particle found by
      %   EXTRACTINDIVIDUALPARTICLES, returning per-particle axes/radii/heights
      %   (Packing) and volume/center/triangulation info (geometricInfo).

      Packing = {};


      for iParticle=1:obj.nParticles

        [TheAxis, TheRadius,TheAxialHeight, center,TheAxis2,TR] = obj.processIndividualParticle(iParticle);
        Packing.AllTheAxes{iParticle} = TheAxis ;
        Packing.AllTheAxes2{iParticle} = TheAxis2 ;
        Packing.AllTheRadii(iParticle) = TheRadius(1) ;
        Packing.AllTheHeights(iParticle) = TheAxialHeight ;

        thisInfo.volume = calculateHexagonalArea(TheRadius(1))*TheAxialHeight;
        thisInfo.center = center;
        thisInfo.axes = TheAxis;
        thisInfo.TR = TR;
        geometricInfo(iParticle) = thisInfo;
      end

    end





    function [TheAxis, TheRadius,TheAxialHeight,center, TheAxis2,Tri2]  = processIndividualParticle(obj,iParticle)
      % PROCESSINDIVIDUALPARTICLE Fit a hexagonal prism's axis, radius and height
      %   to the particle's local triangulation, identified by exploiting the 12
      %   mutually parallel edges that run along the prism's main axis.
      arguments
        obj STLExtractor
        iParticle (1,1) double % particle index to process
      end


      % build a connectivity list for this particle
      localTR = obj.buildLocalTriangulation(iParticle);
      localPoints = localTR.Points;
      localTriangles = localTR.ConnectivityList;

      % localPoints is a (nPoints x 3) matrix, where each row is a point
      % so we get the mean (along each column) to get an estimate of the
      % center of the particle
      % we then "replicate" this mean value to have a matrix of the same size
      % as localPoints, so that we can use it to compute the distance
      % from the center to each point
      xC = repmat(mean(localPoints,1),size(localPoints,1),1) ;

      % construct a list of all edges in the triangles by combining pairwise
      % all the points IDs in the particles triangles
      % the result is a (nEdges x 2) matrix, where each row is an edge
      edges = [...
        localTriangles(:,1),localTriangles(:,2);...
        localTriangles(:,2),localTriangles(:,3);...
        localTriangles(:,3),localTriangles(:,1)...
        ] ;

      % compute the components of all the edges
      % for instance, edgesdx is a vector of the lengths of the edges in the x direction
      edgesdx = localPoints(edges(:,2),1)-localPoints(edges(:,1),1) ;
      edgesdy = localPoints(edges(:,2),2)-localPoints(edges(:,1),2) ;
      edgesdz = localPoints(edges(:,2),3)-localPoints(edges(:,1),3) ;

      % build meshgrids of this components
      % here's the patten:
      %     - TheDX1: all rows are the same, columns are the values of edgesdx
      %     - TheDX2: all columns are the same, rows are the values of edgesdx
      %     TheDX2 == TheDX1'
      [TheDX1,TheDX2] = meshgrid(edgesdx,edgesdx) ;
      [TheDY1,TheDY2] = meshgrid(edgesdy,edgesdy) ;
      [TheDZ1,TheDZ2] = meshgrid(edgesdz,edgesdz) ;

      % edge lengths
      TheDN1 = sqrt(TheDX1.^2+TheDY1.^2+TheDZ1.^2) ;
      TheDN2 = sqrt(TheDX2.^2+TheDY2.^2+TheDZ2.^2) ;

      % Compute the dot products of all edges (as vectors) agains all edges
      TheDots = (TheDX1.*TheDX2 + TheDY1.*TheDY2 + TheDZ1.*TheDZ2)./(TheDN1.*TheDN2) ;

      % Find the edges whose dot product is nearly 1; i.e. are all parallel
      SameDir = abs(TheDots)>.999 ;

      % construct a graph connecting these parallel edges
      Gedges = graph(SameDir) ;

      [binsEdges,binsizes] = conncomp(Gedges) ;
      twelveParallelbin = find(binsizes==12) ;
      if numel(twelveParallelbin) ~= 1
        STLExtractorError.throwError("STLExtractor", "InvalidParticleGeometry", ...
          sprintf("Particle %d: expected exactly one group of 12 parallel edges, found %d.", ...
          iParticle, numel(twelveParallelbin)));
      end
      twelveParallelEdges = find(binsEdges==twelveParallelbin) ;

      k = 1 ;
      TheAxis = [...
        localPoints(edges(twelveParallelEdges(k),2),1)-localPoints(edges(twelveParallelEdges(k),1),1),...
        localPoints(edges(twelveParallelEdges(k),2),2)-localPoints(edges(twelveParallelEdges(k),1),2),...
        localPoints(edges(twelveParallelEdges(k),2),3)-localPoints(edges(twelveParallelEdges(k),1),3)] ;
      TheAxialHeight = norm(TheAxis) ;


      DistFromCenter = sqrt(sum((localPoints-xC).^2,2)) ;
      TheRadius = sqrt(DistFromCenter.^2-(TheAxialHeight/2)^2) ;

      % compute the GeometricType associated with this particle
      gt = GeometricType(TheRadius(1),TheAxialHeight);
      obj.particleGeometry(iParticle) = gt;

      % starting from the second particle, we should compare its
      % geometric type with the others
      if iParticle > 1

        % this is terribly inefficient, but I have yet to find a way
        % to properly overload the comparison operators
        for j = 1:iParticle-1
          if gt == obj.particleGeometry(j)
            % we have found an "identical" particle type,
            % so we assign the same type and exit out of the loop
            obj.particleTypes(iParticle) = obj.particleTypes(j);
            break
          else
            % in this case, change the type
            obj.particleTypes(iParticle) = max(obj.particleTypes) + 1;
            break
          end
        end
      end


      TheAxis = TheAxis./TheAxialHeight ;

      zProjection = dot(TheAxis,[0,0,1]);
      upSign = sign(zProjection);

      if upSign ~= 0
        TheAxis = upSign.*TheAxis ;
      end


      localPoints = (localPoints-xC) + xC ;
      Tri2 = triangulation(localTriangles,localPoints) ;
      center = xC(1,:);
      xC = mean(localPoints,1) ;
      CenterToVertex = localPoints(1,:)-xC ;
      TheAxis2 = CenterToVertex - dot(CenterToVertex,TheAxis).*TheAxis ;
      TheAxis2 = TheAxis2./norm(TheAxis2) ;
      TheAxis3 = cross(TheAxis,TheAxis2) ;


      if obj.shouldSave
        thisFilename = fullfile(obj.saveDir, ...
          ['hexagon_',num2str(iParticle,'%04.0f'),'.stl']);
        stlwrite(Tri2,thisFilename)
      end
    end



    function TR = buildLocalTriangulation(obj,iParticle)
      % BUILDLOCALTRIANGULATION Extract the subset of the global triangulation
      %   belonging to one particle, renumbering its points locally.

      % find the triangle IDs that were grouped into given particle
      % whose index is iParticle
      particlePoints = find(obj.pointsInParticle==iParticle) ;

      nPoints = numel(particlePoints);

      % from the global connectivity list, which lists all triangles and points
      % extracted from the STL file, find only the rows which are pertinent
      % to this particle
      particleConnectivityList = 0.*obj.globalTriangulation.ConnectivityList ;
      for i=1:nPoints
        % particlePoints(i) will return the i-th point index in this particle
        % so we observe where this same index appears in the global matrix
        particleConnectivityList = (particleConnectivityList | ...
          (obj.globalTriangulation.ConnectivityList==particlePoints(i))) ;
      end

      % TODO: Check with Andrea Insinga what's the purpose of this
      particleConnectivityList = (...
        particleConnectivityList(:,1) & ...
        particleConnectivityList(:,1) & ...
        particleConnectivityList(:,1)) ;
      trianglesList = find(particleConnectivityList) ;

      % get only the subset of of global triangulation that contains
      % points in this particle
      T = obj.globalTriangulation.ConnectivityList(trianglesList,:) ;
      % transform from the global point numbering to a local numbering
      T2 = 0.*T ;
      for i=1:nPoints
        T2(T==particlePoints(i)) = i ;
      end

      P = obj.globalTriangulation.Points(particlePoints,:) ;
      TR.Points = P;
      TR.ConnectivityList = T2;

    end

  end


end
