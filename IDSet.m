classdef IDSet < handle
    methods
        function id = register(obj)
            id = obj.newid();
            while obj.hashset.isKey(id)
                id = obj.newid()
            end
            obj.hashset(id) = [];
        end
        
        function deregister(obj, id)
            if obj.hashset.isKey(id)
                obj.hashset.remove(id);
            end
        end
        
        function tf = contains(obj, id)
            tf = obj.hashset.isKey(id);
        end
        
        function clear(obj)
            obj.hashset.remove(obj.hashset.keys);
        end
        
        function value = size(obj)
            value = obj.hashset.Count;
        end
    end
    
    methods (Access = private)
        function id = newid(obj)
            id = num2str(rand(), '%.16f');
        end
    end
    
    methods
        function obj = IDSet()
            obj.hashset = containers.Map('keyType', 'char', 'valueType', 'any');
        end
    end
    
    properties (Access = protected)
        hashset
    end
end
