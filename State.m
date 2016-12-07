classdef State < handle
    methods
        function clear(obj)
            obj.package = [];
            obj.datarcd.init();
        end
    end
    
    methods
        function obj = State(n)
            if not(exist('n', 'var'))
                obj.datarcd = Queue('capacity', 1, '-dropold');
            else
                obj.datarcd = Queue('capacity', n, '-dropold');
            end
        end
    end
    
    properties
        package
    end
    properties (Dependent)
        data, capacity
    end
    properties %(Access = protected)
        datarcd
    end
    methods
        function value = get.data(obj)
            if obj.datarcd.isempty
                value = [];
            else
                value = obj.datarcd.stackpop();
            end
        end
        function set.data(obj, value)
            obj.datarcd.push(value);
        end
        
        function value = get.capacity(obj)
            value = obj.datarcd.capacity;
        end
        function set.capacity(obj, value)
            obj.datarcd.capacity = value;
        end
    end
end
