
classdef testPackingFigureRenderer < matlab.unittest.TestCase

    methods (Test)


        function test_two_different_particles_have_different_colors(testCase)
            % Specify the input(s) of
            % ExtractedPacking
            
            % Create two different prisms, with different radii but same height

            r1 = 1.0;
            r2 = 1.2;
            t = 0.5;
            position1 = [1,2,3];
            position2 = [-2,6,0.5];
            normal = [0,0,1];
            fR = [1,0,0];
            hps = [...
                HexagonalPrism(position1, r1, t, normal, fR),...
                HexagonalPrism(position2, r2, t, normal, fR),...
                ];

            % we'd like to be able to retrieve a figure
            % (since coloring only makes sense when plotting)
            r = PackingFigureRenderer;

            % now we'd like to be able to say something like that:
            testCase.verifyNotEqual( ...
                r.colorOf(hps(1)), r.colorOf(hps(2)));
        end

    end
      
end