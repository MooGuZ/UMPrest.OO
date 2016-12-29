classdef SimpleAP < AccessPoint
    methods
        function send(obj, package)
            send@AccessPoint(obj, package);
            obj.packagercd = package;
        end
        
        function package = pop(obj)
            package = pop@AccessPoint(obj);
            obj.packagercd = package;
        end
        
        function package = pull(obj)
            package = pull@AccessPoint(obj);
            obj.packagercd = package;
        end
    end
    
    methods
        function obj = SimpleAP(parent, capacity)
            obj.parent = parent;
            if exist('capacity', 'var')
                obj.cache = Container(capacity);
            else
                obj.cache = Container();
            end
        end
    end
    
    properties (SetAccess = protected)
        parent, cache
    end
    methods
        function set.parent(obj, value)
            assert(isa(value, 'Unit'), 'ILLEGAL ASSIGNMENT');
            obj.parent = value;
        end
        
        function set.cache(obj, value)
            assert(isa(value, 'Container'), 'ILLEGAL ASSIGNMENT');
            obj.cache = value;
        end
    end
end
