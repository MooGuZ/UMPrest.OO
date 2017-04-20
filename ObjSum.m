classdef ObjSum < Objective
    methods
        function value = evaluate(obj, x)
            if not(exist('x', 'var'))
                x = obj.x.pop();
            end
            if isa(x, 'DataPackage')
                value = sum(x.data(:));
            else
                value = sum(x(:));
            end
        end
        
        function errpack = delta(obj, x)
            if not(exist('x', 'var'))
                x = obj.x.pop();
            end
            if isa(x, 'DataPackage')
                errpack = ErrorPackage(ones(size(x.data)), x.dsample, x.taxis);
            else
                errpack = ErrorPackage(ones(size(x)), max(nndims(x), 1), false);
            end
            if nargout == 0
                obj.x.send(errpack);
            end
        end
    end
    
    methods
        function obj = ObjSum()
            obj.x = SimpleAP(obj);
        end
    end
    
    properties
        x
    end
end