classdef Unit < Interface
    methods
        function obj = Unit()
            obj.id = obj.uid.register(obj);
        end
        
        function delete(obj)
            obj.uid.deregister(obj.id);
        end
    end
    
    properties (SetAccess = private, Transient, Hidden)
        id % system-wise identified, distributed by UMPrest
    end
    properties (GetAccess = private, Constant)
        uid = UMPrest.UnitIDManager();
    end
    methods
        function value = get.id(obj)
            % this operation is to register unit after loading from file
            if isempty(obj.id)
                obj.id = obj.uid.register(obj);
            end
            value = obj.id;
        end
    end
end
