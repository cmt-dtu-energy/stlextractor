classdef PackingFigureRenderer < handle
    %PACKINGFIGURERENDERER Assign consistent, distinct colors to prism types
    %   A PackingFigureRenderer assigns each distinct HEXAGONALPRISM type
    %   (identified by its radius and thickness) a unique, visually distinct
    %   color from a fixed categorical palette, and remembers that mapping so
    %   repeated calls return the same color. Instances are created
    %   automatically by EXTRACTEDPACKING's constructor (as its 'renderer'
    %   property) and used by EXTRACTEDPACKING.PLOT.
    %
    % See also EXTRACTEDPACKING, HEXAGONALPRISM
    %
    % This class was designed with the help of Claude AI.

    properties (Access = private)
        colorMap containers.Map % a mapping of char vectors to a row of `colorScheme` (see below)
        colorScheme (:,3) double % a matrix of possible RGB vectors to color the particles
        colorIndex (1,1) double = 0 % current row of the matrix above
        prisms (1,:) HexagonalPrism
    end

    methods
        function obj = PackingFigureRenderer(prisms)
            %PACKINGFIGURERENDERER Build a renderer and pre-assign colors
            %
            %   r = PACKINGFIGURERENDERER(prisms) builds a renderer for the
            %       given array of HexagonalPrism objects, assigning each
            %       distinct (radius,thickness) type a color up front so that
            %       COLOROF can look it up later.


            % Initialize color map and scheme
            obj.colorMap = containers.Map();
            obj.colorScheme = obj.getCategoricalColorScheme();
            obj.prisms = prisms;
            obj.buildColorTable;
        end

        function color = colorOf(obj, hexPrism)
            %COLOROF Return a unique color for each different prism type
            %
            % Two prisms are considered different if their radius or
            % thickness properties differ

            arguments
                obj PackingFigureRenderer
                hexPrism HexagonalPrism
            end
            
            % Create unique key based on radius and thickness
            key = sprintf('r%.6f_t%.6f', hexPrism.radius, hexPrism.thickness);

            color = obj.colorMap(key);
        end
    end

    methods (Access = private)
        function colors = getCategoricalColorScheme(~)
            %GETCATEGORICALCOLORSCHEME Return a visually distinct color scheme
            %
            % Uses a combination of qualitative color schemes optimized
            % for categorical data visualization

            colors = [
                0.819, 0.745, 0.803;  % Bright Pink
                0.1, 0.8, 0.7;  % Bright Cyan
                0.1725, 0.6275, 0.1725;  % Bright Green
                0.8392, 0.1529, 0.1569;  % Bright Red
                0.5804, 0.4039, 0.7412;  % Bright Purple
                0.5490, 0.3373, 0.2941;  % Bright Brown
                0.4980, 0.4980, 0.4980;  % Bright Gray
                0.7373, 0.7412, 0.1333;  % Bright Olive
                0.0902, 0.7451, 0.8118;  % Bright Cyan
                1.0000, 0.7333, 0.4706;  % Light Orange
                0.6000, 0.8000, 0.1961;  % Lime Green
                1.0000, 0.2000, 0.6000;  % Hot Pink
                0.4000, 0.8000, 1.0000;  % Sky Blue
                1.0000, 0.8000, 0.2000;  % Bright Yellow
                0.8000, 0.2000, 1.0000;  % Bright Magenta
                ];
        end
    
        function buildColorTable(obj)
            % BUILDCOLORTABLE Populate colorMap with one color per distinct
            %   prism type, assigning colors in order of increasing radius so
            %   the mapping is deterministic regardless of input order.

            % Sort the prisms array by the radius of each element
            [~, sortedIndices] = sort([obj.prisms.radius]);
            obj.prisms = obj.prisms(sortedIndices);
            % Create unique key based on radius and thickness
            for hexPrism = obj.prisms
                key = sprintf('r%.6f_t%.6f', hexPrism.radius, hexPrism.thickness);
    
                % Check if we already have a color for this prism type
                if isKey(obj.colorMap, key)
                    
                else
                    % Assign new color from scheme
                    obj.colorIndex = obj.colorIndex + 1;
                    colorIdx = mod(obj.colorIndex - 1, size(obj.colorScheme, 1)) + 1;
                    color = obj.colorScheme(colorIdx, :);
    
                    % Store in map
                    obj.colorMap(key) = color;
                end
            end
        end
    end
end