classdef Task < handle
    methods (Static)
        function info = classify(x, ref)
            [~, indexA] = max(x, [], 1);
            [~, indexB] = max(ref, [], 1);
            n = sum(indexA(:) == indexB(:));
            m = numel(indexA);
            info = sprintf('%13s >> %.2f%% accuracy (%d / %d)', 'CLASSIFY', n / m , n, m);
        end
    end
    
    methods
        function obj = Task(type)
            switch lower(type)
              case {'classify'}
                obj.run = @Task.classify;
                
              otherwise
                error('UMPrest:ArgumentError', 'Unrecognized task type : %s', ...
                      upper(type));
            end
        end
    end
    
    properties
        run
    end
    methods
        function set.run(obj, value)
            assert(isa(value, 'function_handle'));
            obj.run = value;
        end
    end
end
