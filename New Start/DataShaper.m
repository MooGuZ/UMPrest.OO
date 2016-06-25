classdef DataShaper < Unit
    methods
        function y = transproc(obj, x)
            y = reshape(x, obj.shape.out);
        end
        
        function x = inferproc(obj, y)
            x = obj.errprop(y);
        end
        
        function d = errprop(obj, d)
            d = reshape(d, obj.shape.in);
        end
    end
    
    methods
        function obj = DataShaper(inShape, outShape)
            assert(not(isempty(inShape) && isempty(outShape)), ...
                'UMPrest:ArgumentError', 'INSHAPE and OUTSHAPE cannot be both empty');
            
            obj.shape = struct('in', inShape, 'out', outShape);
            
            if isempty(inShape)
                obj.shape.in = [prod(outShape), 1];
            end
            
            if isempty(outShape)
                obj.shape.out = [prod(inShape), 1];
            end
            
            assert(prod(obj.shape.in) == prod(obj.shape.out), ...
                'UMPrest:ArgumentError', 'DataShaper cannot change number of elements');
        end
    end
    
    properties
        shape
    end
end