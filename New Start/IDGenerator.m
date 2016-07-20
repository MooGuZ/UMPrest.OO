classdef IDGenerator < handle
    methods
        function refresh(obj)
            obj.counter = 0;
        end
        
        function id = next(obj, n)
            if not(exist('n', 'var'))
                n = 1;
            end
            
            if n == 1
                id = [obj.prefix, num2str(obj.counter)];
            else
                id = arrayfun(@(i) strcat(obj.prefix, num2str(i)), ...
                    obj.counter + (1 : n), 'UniformOutput', false);
            end
            obj.counter = obj.counter + n;
        end
    end
    
    methods
        function obj = IDGenerator(prefix)
            obj.prefix = prefix;
        end
    end
    
    properties
        prefix, counter = 0;
    end
    methods
        function set.prefix(obj, value)
            assert(ischar(value));
            obj.prefix = value;
        end
    end
end
