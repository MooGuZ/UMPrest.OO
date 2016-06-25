classdef Task < handle
    methods (Static)
        function list = typelist()
            list = {'classify'};
        end
        
        function classify(x, ref)
            [~, indexA] = max(x, [], 1);
            [~, indexB] = max(ref, [], 1);
            n = sum(indexA(:) == indexB(:));
            m = numel(indexA);
            fprintf('%13s >> %.2f%% accuracy (%d / %d)\n', 'CLASSIFY', n / m , n, m);
        end
    end
end
