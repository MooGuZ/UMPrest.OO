classdef DDModel < Model
% Distinguish Distribution Model
    methods
        function obj = DDModel(transUnit, distUnit)
            shaper = Reshaper().appendto(transUnit.O{1}).aheadof(distUnit.I{1});
            obj@Model(transUnit, shaper, distUnit);
            obj.transUnit = transUnit;
            obj.distUnit  = distUnit;
        end
    end
    
    methods
        function modeldump = dump(obj)
            modeldump = {'DDModel', obj.transUnit.dump(), obj.distUnit.dump()};
        end
    end
    
    properties
        transUnit, distUnit
    end
end
