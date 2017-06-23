classdef Unit < Interface
    methods
        function obj = Unit()
            obj.id = obj.idset.register();
        end
        
        function delete(obj)
            obj.idset.deregister(obj.id);
        end
        
        function self = isolate(self)
            for i = 1 : numel(obj.I)
                obj.I{i}.isolate();
            end
            for i = 1 : numel(obj.O)
                obj.O{i}.isolate();
            end
        end
    end
    
    properties (Constant, Hidden)
        idset = IDSet()
    end
    properties (SetAccess = private, Hidden)
        id
    end
end
