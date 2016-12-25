classdef Unit < Interface
    methods
        function obj = Unit()
            obj.id = obj.idset.register();
        end
        
        function delete(obj)
            obj.idset.deregister(obj.id);
        end
    end
    
    properties (Constant, Hidden)
        idset = IDSet()
    end
    properties (SetAccess = private, Hidden)
        id
    end
end
