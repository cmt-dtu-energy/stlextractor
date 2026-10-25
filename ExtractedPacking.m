classdef ExtractedPacking < handle
    %EXTRACTEDPACKING Packing of hexagonal prisms extracted from a mesh file
    %   An ExtractedPacking wraps an array of HEXAGONALPRISM objects (its ITEMS)
    %   together with the geometric bounds, dimensions, volume, filling fraction
    %   and per-axis alignment statistics of the packing as a whole. It is the
    %   object returned by STLEXTRACTOR.PROCESS, and is normally not constructed
    %   directly.
    %
    %   ep = EXTRACTEDPACKING(prisms) builds a packing from an array of
    %       HexagonalPrism objects, computing all geometric properties below.
    %
    % See also STLEXTRACTOR, HEXAGONALPRISM

    properties
        renderer % PACKINGFIGURERENDERER used by PLOT to assign a consistent color to each distinct prism type
    end

    properties (SetAccess = private)
        items (1,:) HexagonalPrism % Array of HexagonalPrism objects that make up this packing
    end

    % --- Geometry bounds: axis-aligned bounding box of all prism vertices ---
    properties (SetAccess = private)
        xmin (1,1) double % Minimum x-coordinate over all prism vertices
        xmax (1,1) double % Maximum x-coordinate over all prism vertices
        ymin (1,1) double % Minimum y-coordinate over all prism vertices
        ymax (1,1) double % Maximum y-coordinate over all prism vertices
        zmin (1,1) double % Minimum z-coordinate over all prism vertices
        zmax (1,1) double % Maximum z-coordinate over all prism vertices
    end

    % --- Dimensions and volume of the bounding box ---
    properties (SetAccess = private)
        Lx (1,1) double % Bounding-box side length along x (xmax - xmin)
        Ly (1,1) double % Bounding-box side length along y (ymax - ymin)
        Lz (1,1) double % Bounding-box side length along z (zmax - zmin)
        volume (1,1) double % Bounding-box volume (Lx * Ly * Lz); the denominator used by volumetricFillingFraction
    end

    % --- Filling fraction ---
    properties (SetAccess = private)
        volumetricFillingFraction (1,1) double % Fraction of the bounding-box volume occupied by prisms: sum(items.volume) / volume, in [0,1]
    end

    % --- Alignment statistics: how well each prism's normal aligns with the x, y and z axes ---
    % For a given axis, "alignment" of one prism is dot(prism.normal, axisVector), i.e. the
    % cosine of the angle between the prism's axis and that coordinate axis (so it lies in [-1,1]).
    properties (SetAccess = private)
        averageAlignmentX (1,1) double % Mean alignment of all prisms' normals with the x-axis
        standardDeviationAlignmentX (1,1) double % Standard deviation of prisms' alignment with the x-axis
        volumeWeightedAverageAlignmentX (1,1) double % Volume-weighted mean alignment with the x-axis (each prism weighted by its volume)
        volumeWeightedStandardDeviationAlignmentX (1,1) double % Volume-weighted standard deviation of alignment with the x-axis
        averageAlignmentY (1,1) double % Mean alignment of all prisms' normals with the y-axis
        standardDeviationAlignmentY (1,1) double % Standard deviation of prisms' alignment with the y-axis
        volumeWeightedAverageAlignmentY (1,1) double % Volume-weighted mean alignment with the y-axis (each prism weighted by its volume)
        volumeWeightedStandardDeviationAlignmentY (1,1) double % Volume-weighted standard deviation of alignment with the y-axis
        averageAlignmentZ (1,1) double % Mean alignment of all prisms' normals with the z-axis
        standardDeviationAlignmentZ (1,1) double % Standard deviation of prisms' alignment with the z-axis
        volumeWeightedAverageAlignmentZ (1,1) double % Volume-weighted mean alignment with the z-axis (each prism weighted by its volume)
        volumeWeightedStandardDeviationAlignmentZ (1,1) double % Volume-weighted standard deviation of alignment with the z-axis
    end



    methods
        function obj = ExtractedPacking(prisms,options)
            %EXTRACTEDPACKING Construct a packing from an array of hexagonal prisms
            %
            %   ep = EXTRACTEDPACKING(prisms) will create a packing from a given
            %       array of HEXAGONALPRISM objects, computing its bounds,
            %       dimensions, volume, filling fraction and alignment statistics.
            %
            %   ep = EXTRACTEDPACKING(prisms,'ZMinLimit',zmin) / ...,'ZMaxLimit',zmax)
            %       additionally discard prisms below zmin, or above zmax,
            %       before computing the packing's statistics.
            %
            %   ep = EXTRACTEDPACKING(prisms,'BoundingBoxLength',L) additionally
            %       discards prisms whose x- or y-extent falls outside a square
            %       of side L centered at the origin.
            arguments
                prisms (1,:) HexagonalPrism
                options.BoundingBoxLength (1,1) double = NaN
                options.ZMinLimit (1,1) double = NaN % Minimum limit of z-position to include particles (will eliminate particles below this position
                options.ZMaxLimit (1,1) double = NaN % Maximum limit of z-position to include particles (will eliminate particles above this position
            end
            obj.items = prisms;
            obj.initializeLimitsAndStatistics;
            obj.renderer = PackingFigureRenderer(prisms);

            % remove particles whose z-position are lower than the prescribed limit
            if ~isnan(options.ZMinLimit)
                if obj.zmin < options.ZMinLimit
                    obj = obj.filterPacking("z",options.ZMinLimit,obj.zmax);
                end
            end


            % remove particles whose z-position are bigger than the prescribed limit
            if ~isnan(options.ZMaxLimit)
                obj = obj.filterPacking("z",0,options.ZMaxLimit);
            end

            % apply bounding box length filter
            if ~isnan(options.BoundingBoxLength)
                xlim = options.BoundingBoxLength/2;
                if (obj.xmax > xlim) || (obj.xmin < -xlim)
                    obj = obj.filterPacking("x",-xlim,xlim);
                end
                % we can use the same xlim for y, because we assume
                % that the packing is roughly cubic
                if (obj.ymax > xlim) || (obj.ymin < -xlim)
                    obj = obj.filterPacking("y",-xlim,xlim);
                end
            end

        end

        function outputArg = length(obj)
            %LENGTH Return the number of extracted particles in this packing
            outputArg = length(obj.items);
        end


        function f = plot(obj)
            %PLOT Render the packing's prisms in a new 3-D figure.
            %   Each prism is colored according to its type (radius/thickness)
            %   using obj.renderer, and the figure is centered on the packing's
            %   bounding box.

            % change width and height
            % from: https://se.mathworks.com/help/releases/R2024b/matlab/ref/figure.html#bvjs6cb-3

            f = figure;
            f.Units = "centimeters";
            f.Position(3:4) = [16,9];
            r = obj.renderer;
            hold on

            axis equal
            light('position',[2,2,2])
            view(30,30) ;
            xlabel("x");
            ylabel("y");
            zlabel("z");

            centerx = mean([obj.xmin,obj.xmax]);
            centery = mean([obj.ymin,obj.ymax]);
            centerz = mean([obj.zmin,obj.zmax]);

            for i = 1:length(obj)
                hp = obj.items(i);
                TR = hp.triangulation;
                T = TR.ConnectivityList;
                P = TR.Points - [centerx,centery,centerz];
                trisurf(T,P(:,1),P(:,2),P(:,3), ...
                    "FaceColor",r.colorOf(hp), ...
                    'linestyle','none', ...
                    'facealpha',1, ...
                    'SpecularStrength',0.1, ...
                    'AmbientStrength',0.6)
            end

            hold off

        end



        function ep = cutoff(obj,margin,startDirection,options)
            %CUTOFF Trim all sides of the packing toward a smaller cube-like region
            %
            %   epNew = CUTOFF(obj,margin) removes a fraction 'margin' of the
            %       side length from every side (x, y and z), symmetrically,
            %       returning the resulting smaller ExtractedPacking.
            %
            %   epNew = CUTOFF(obj,margin,startDirection) is equivalent, and
            %       startDirection only selects which axis' current length is
            %       used as the reference side length to shrink (all three axes
            %       are always trimmed).
            %
            %   epNew = CUTOFF(___,'Method',CUTOFFMETHOD.centers) selects
            %       particles to remove by their center position instead of by
            %       their vertices (the default).
            %
            % See also CUTOFFZ, CUTOFFMETHOD
            arguments
                obj 
                margin (1,1) double % Fraction of the side length to remove
                startDirection (1,1) string {mustBeMember(startDirection, ["x","y","z"])} = "x" % From which direction to start cutting
                options.Method (1,1) CutoffMethod = CutoffMethod.vertices; % Method to use to select items to cut. If 'vertices', items with any vertice that is beyond the cutplane are removed; if 'centers', then only items whose center are beyond the cut planes are removed.
            end

            switch startDirection
                case "x"
                    Lnew = obj.Lx*(1-margin);
                case "y"
                    Lnew = obj.Ly*(1-margin);
                case "z"
                    Lnew = obj.Lz*(1-margin);
                otherwise
                    STLExtractorError.throwError('ExtractedPacking', 'InvalidDirection', ...
                        'Unrecognized direction to start cutoff process')
            end

            dx = (obj.Lx - Lnew)/2;
            dy = (obj.Ly - Lnew)/2;
            dz = (obj.Lz - Lnew)/2;


            xmaxpost = obj.xmax - dx;
            xminpost = obj.xmin + dx;
            ymaxpost = obj.ymax - dy;
            yminpost = obj.ymin + dy;
            zmaxpost = obj.zmax - dz;
            zminpost = obj.zmin + dz;



            ep = filterPacking(obj,"x",xminpost,xmaxpost, "Method",options.Method);
            ep = filterPacking(ep,"y",yminpost,ymaxpost, "Method",options.Method);
            ep = filterPacking(ep,"z",zminpost,zmaxpost, "Method",options.Method);



        end

        function ep = cutoffz(obj,options)
            %CUTOFFZ Trim only the z-direction so the packing becomes cube-like
            %
            %   epNew = CUTOFFZ(obj) trims the top and bottom of the packing so
            %       that its z-extent matches the average of its x- and
            %       y-extents, returning the resulting ExtractedPacking. The x
            %       and y directions are left unchanged.
            %
            %   epNew = CUTOFFZ(obj,'Method',CUTOFFMETHOD.centers) selects
            %       particles to remove by their center position instead of by
            %       their vertices (the default).
            %
            % See also CUTOFF, CUTOFFMETHOD
            arguments
                obj 
                options.Method (1,1) CutoffMethod = CutoffMethod.vertices; % Method to use to select items to cut. If 'vertices', items with any vertice that is beyond the cutplane are removed; if 'centers', then only items whose center are beyond the cut planes are removed.
            end

            Lznew = 0.5*(obj.Lx + obj.Ly);

            dz = (obj.Lz - Lznew)/2;

            zmaxpost = obj.zmax - dz;
            zminpost = obj.zmin + dz;

            ep = filterPacking(obj,"z",zminpost,zmaxpost,"Method",options.Method);

        end

    end

    methods (Access = private)

        function initializeLimitsAndStatistics(obj)
            % INITIALIZELIMITS Define the i-{min,max} attributes (e.g. "xmin","ymax" etc)

            % 12 because there 2 faces of 6 vertices in each prism;
            nVertices = 12 * length(obj);
            xvalues = zeros(1,nVertices);
            yvalues = zeros(1,nVertices);
            zvalues = zeros(1,nVertices);

            for iPrism = 1:length(obj)
                hp = obj.items(iPrism);
                idxmin = 12*(iPrism-1)+1;
                idxmax = 12*(iPrism-1)+12;
                xvalues(idxmin:idxmax) = hp.vertices(:,1);
                yvalues(idxmin:idxmax) = hp.vertices(:,2);
                zvalues(idxmin:idxmax) = hp.vertices(:,3);

            end

            obj.xmin = min(xvalues);
            obj.xmax = max(xvalues);
            obj.ymin = min(yvalues);
            obj.ymax = max(yvalues);
            obj.zmin = min(zvalues);
            obj.zmax = max(zvalues);
            obj.Lx = obj.xmax - obj.xmin;
            obj.Ly = obj.ymax - obj.ymin;
            obj.Lz = obj.zmax - obj.zmin;
            obj.volume = obj.Lx * obj.Ly * obj.Lz;

            volumes = arrayfun(@(hp) hp.volume,obj.items);
            prismsVolume = sum(volumes);

            obj.volumetricFillingFraction = prismsVolume/obj.volume;

            obj.averageAlignmentX = obj.averageAlignment("x");
            obj.standardDeviationAlignmentX = obj.standardDeviationAlignment("x");
            obj.volumeWeightedAverageAlignmentX = obj.volumeWeightedAverageAlignment("x");
            obj.volumeWeightedStandardDeviationAlignmentX = obj.volumeWeightedStandardDeviationAlignment("x");

            obj.averageAlignmentY = obj.averageAlignment("y");
            obj.standardDeviationAlignmentY = obj.standardDeviationAlignment("y");
            obj.volumeWeightedAverageAlignmentY = obj.volumeWeightedAverageAlignment("y");
            obj.volumeWeightedStandardDeviationAlignmentY = obj.volumeWeightedStandardDeviationAlignment("y");

            obj.averageAlignmentZ = obj.averageAlignment("z");
            obj.standardDeviationAlignmentZ = obj.standardDeviationAlignment("z");
            obj.volumeWeightedAverageAlignmentZ = obj.volumeWeightedAverageAlignment("z");
            obj.volumeWeightedStandardDeviationAlignmentZ = obj.volumeWeightedStandardDeviationAlignment("z");

        end

        function ep = filterPacking(obj,direction,vmin,vmax,options)
           % FILTERPACKING Keep only items within [vmin,vmax] along one axis,
           %   returning a new ExtractedPacking built from the surviving items.
           arguments
                obj 
                direction (1,1) string {mustBeMember(direction, ["x","y","z"])} = "x"; % From which direction to start cutting
                vmin (1,1) double = 0; % minimum value of the "direction" above, above which items will remain
                vmax (1,1) double = 0; % maximum value of the "direction" above, below which items will remain
                options.Method (1,1) CutoffMethod = CutoffMethod.vertices; % Method to use to select items to cut. If 'vertices', items with any vertice that is beyond the cutplane are removed; if 'centers', then only items whose center are beyond the cut planes are removed.
            end

            pre = obj.items;
            nHexagons = numel(pre);
            hexagonPositionsMin = zeros(nHexagons,3);
            hexagonPositionsMax = zeros(nHexagons,3);
            for iPrism = 1:length(obj)
                hp = obj.items(iPrism);
                for j = [1,2,3]
                    if options.Method == CutoffMethod.vertices
                        hexagonPositionsMin(iPrism,j) = min(hp.vertices(:,j));
                        hexagonPositionsMax(iPrism,j) = max(hp.vertices(:,j));
                    else
                       % For the 'centers' method, both min and max are set to the center position.
                       % This allows the filtering logic to work uniformly for both methods.
                       hexagonPositionsMin(iPrism,j) = hp.position(j);
                       hexagonPositionsMax(iPrism,j) = hp.position(j);
                    end
                end
            end

            switch direction
                case "x"
                    ax = 1;
                case "y"
                    ax = 2;
                case "z"
                    ax = 3;
            end
            indx = find(hexagonPositionsMin(:,ax) >= vmin & hexagonPositionsMax(:,ax) <= vmax);
            if isempty(indx)
                STLExtractorError.throwError('ExtractedPacking', 'NoParticlesInRange', ...
                    sprintf('No particles found in the specified %s range (%.3g, %.3g).', direction, vmin, vmax));
            end
            nl = pre(indx);
            ep = ExtractedPacking(nl);
        end

        function out = averageAlignment(obj,direction)
            % AVERAGEALIGNMENT Compute mean of alignments of items along given direction
            v = getDirectionVector(direction);
            alignments = arrayfun(@(hp) dot(hp.normal,v),obj.items);
            out = mean(alignments);
        end

        function out = standardDeviationAlignment(obj,direction)
            % STANDARDDEVIATIONALIGNMENT Compute standard deviation of alignments of items along
            % given direction
            v = getDirectionVector(direction);
            alignments = arrayfun(@(hp) dot(hp.normal,v),obj.items);
            out = std(alignments);
        end

        function out = volumeWeightedAverageAlignment(obj,direction)
            % VOLUMEWEIGHTEDAVERAGEALIGNMENT Compute mean of alignments of items along
            % given direction, weighted by the volume of each item
            v = getDirectionVector(direction);
            alignments = arrayfun(@(hp) dot(hp.normal,v),obj.items);
            weights = arrayfun(@(hp) hp.volume,obj.items);
            % we need the conversion factor below because our definition
            % use the cube volume, and not the total volume, in the
            % denominator
            out = mean(alignments,"Weights",weights)*obj.volumetricFillingFraction;
        end

        function out = volumeWeightedStandardDeviationAlignment(obj,direction)
            % VOLUMEWEIGHTEDSTANDARDDEVIATIONALIGNMENT Compute mean of alignments of
            % items along given direction, weighted by the volume of each item
            v = getDirectionVector(direction);
            alignments = arrayfun(@(hp) dot(hp.normal,v),obj.items);
            weights = arrayfun(@(hp) hp.volume,obj.items);
            % we need the conversion factor below because our definition
            % use the cube volume, and not the total volume, in the
            % denominator
            out = std(alignments,weights)*sqrt(obj.volumetricFillingFraction);
        end
    end


end


