function v = getDirectionVector(direction)
            % GETDIRECTIONVECTOR Unit vector for "x"/"y"/"z"; errors otherwise
            switch direction
                case "x"
                    v = [1,0,0];
                case "y"
                    v = [0,1,0];
                case "z"
                    v = [0,0,1];
                otherwise
                    STLExtractorError.mustBeValidDirection(direction)
            end
end