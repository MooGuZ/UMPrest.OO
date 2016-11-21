% PROPOSAL: add capability to deal with not-concrete size description in a fast way
classdef DataShaper < Unit
    methods
        function y = transform(obj, x)
            nsample = size(x, numel(obj.inputSizeDescription));
            y = reshape(x, [obj.sizeout, nsample]);
        end
        
        function x = compose(obj, y)
            nsample = size(y, numel(obj.outputSizeDescription));
            x = reshape(y, [obj.sizein, nsample]);
        end
        
        function d = errprop(obj, d, ~)
            d = obj.compose(d);
        end
    end
    
    methods
        function obj = DataShaper(insize, outsize)
            assert(prod(insize) == prod(outsize), 'UMPrest:ArgumentError', ...
                   'DataShaper cannot change number of elements');
            obj.insize  = insize;
            obj.outsize = outsize;
        end
    end
    
    properties (Hidden, SetAccess = private)
        insize, outsize
    end
    methods
        function set.insize(obj, value)
            assert(MathLib.isinteger(value) && all(value > 0));
            if numel(value) == 1
                obj.insize = [value, 1];
            else
                obj.insize = value;
            end
        end
        
        function set.outsize(obj, value)
            assert(MathLib.isinteger(value) && all(value > 0));
            if numel(value) == 1
                obj.outsize = [value, 1];
            else
                obj.outsize = value;
            end
        end
    end
    
    properties (Dependent)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(obj)
            value = SizeDescription.format(obj.insize);
        end
        
        function descriptionOut = sizeIn2Out(obj, ~)
            descriptionOut = SizeDescription.format(obj.outsize);
        end
    end
end
