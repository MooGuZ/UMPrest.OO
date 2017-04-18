classdef ObjSum < Objective
    methods
        function value = evaluate(~, x)
            if isa(x, 'DataPackage')
                value = sum(x.data(:));
            else
                value = sum(x(:));
            end
        end
        
        function errpack = delta(obj, x)
            if isa(x, 'DataPackage')
                errpack = ErrorPackage(ones(size(x.data)), x.dsample, x.taxis);
            else
                errpack = ErrorPackage(ones(size(x)), max(nndims(x), 1), false);
            end
        end
    end
end