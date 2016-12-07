classdef IDManager < handle
    methods
        function id = register(obj, unit)
            id = num2str(rand(), obj.format);
            while obj.id2unit.isKey(id)
                id = rand();
            end
            obj.id2unit(id) = unit;
        end
        
        function deregister(obj, id)
            if obj.id2unit.isKey(id)
                obj.id2unit.remove(id);
            end
        end
        
        function unit = find(obj, id)
            if obj.id2unit.isKey(id)
                unit = obj.id2unit(id);
            else
                unit = [];
            end
        end
        
        function idset = ids(obj)
            idset = obj.id2unit.keys();
        end
        
        function unitset = units(obj)
            unitset = obj.id2unit.values();
        end
        
        function clear(obj)
            obj.id2unit.remove(obj.id2unit.keys);
        end
    end
    
    methods
        function obj = IDManager()
            obj.id2unit = containers.Map('keyType', 'char', 'valueType', 'any');
        end
    end
    
    properties % (Access = protected)
        id2unit % map contains all connections between id and unit
    end
    properties
        format = '%.16f' % id pattern
    end
    properties (Dependent)
        count
    end
    methods
        function value = get.count(obj)
            value = obj.id2unit.Count;
        end
    end
end