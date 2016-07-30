classdef Vectorizer < Unit
    methods
        function data = transform(obj, data)
            data = MathLib.vec(data, obj.dim, 'front');
        end
        
        function data = compose(obj, data)
            if obj.matured
                dataSize   = size(data);
                sampleSize = dataSize(2 : end);
                data = reshape(data, ...
                               [double(obj.inputSizeDescription), sampleSize]);
            else
                error('Operation is forbidden before Vectorizer matured');
            end
        end
        
        function delta = errprop(obj, delta, ~)
            delta = obj.compose(delta);
        end
        
        function unit = inverseUnit(obj)
            if obj.matured
                unit = DataShaper( ...
                    double(obj.outputSizeDescription), ...
                    double(obj.inputSizeDescription));
            else
                error('Inverse unit is unavailable before Vectorizer matured');
            end
        end
    end
    
    properties (Dependent)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(obj)
            value  = SizeDescription.format(nan(1, obj.dim));
        end
        
        function descriptionOut = sizeIn2Out(~, descriptionIn)
            descriptionOut = prod(descriptionIn);
        end
    end
    
    methods
        function obj = Vectorizer(dim)
            obj.dim = dim; 
        end
    end
    
    properties
        dim
    end
    properties (Dependent)
        matured
    end
    methods
        function value = get.matured(obj)
            value = SizeDescription.isnumeric(obj.inputSizeDescription);
        end
    end
end
