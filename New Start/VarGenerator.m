classdef VarGenerator < handle
    methods
        function vars = next(obj, n)
            if exist('n', 'var')
                vars = sym(obj.idgen.next(n), 'clear');
            else
                vars = sym(obj.idgen.next(1), 'clear');
            end
        end
        
        function refresh(obj)
            obj.idgen.refresh();
        end
    end
    
    methods
        function obj = VarGenerator(namePrefix)
            obj.idgen = IDGenerator(namePrefix);
        end
    end
    
    properties
        idgen
    end
    methods
        function set.idgen(obj, value)
            assert(isa(value, 'IDGenerator'));
            obj.idgen = value;
        end
    end
end
