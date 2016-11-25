classdef Unit < Interface
    properties
        id
    end
    
    methods
        function obj = Unit()
            % register current unit at UMPrest (central controller)
            obj.id = UMPrest.unit(obj);
        end
    end
end
