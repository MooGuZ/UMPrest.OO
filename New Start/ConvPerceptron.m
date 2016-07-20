classdef ConvPerceptron < MappingUnit
    methods
        function y = process(obj, x)
            y = obj.act.transform(obj.pool.transform(obj.conv.transform(x)));
        end
        
        function d = errprop(obj, d)
            d = obj.conv.errprop(obj.pool.errprop(obj.act.errprop(d)));
        end
        
        function update(obj, stepsize)
            if exist('stepsize', 'var')
                obj.conv.update(stepsize);
            else
                obj.conv.update();
            end
        end
        
        function unit = inverseUnit(obj)
            unit = obj; % TEMPORAL
        end
    end
    
    properties (Dependent)
        inputSizeRequirement
    end
    properties
        outputSizePattern
    end
    methods
        function value = get.inputSizeRequirement(obj)
            value = obj.conv.inputSizeDescription;
        end
        
        function set.outputSizePattern(obj, value)
            assert(isstruct(value) && all(isfield(value, {'in', 'out'})));
            assert(SizeDescription.islegal(value.in) && ...
                   SizeDescription.isconcrete(value.out));
            obj.outputSizePattern = value;
        end
        
        function descriptionOut = sizeIn2Out(obj, descriptionIn)
            descriptionOut = SizeDescription.applyPattern( ...
                descriptionIn, obj.outputSizePattern);
        end
    end
    
    methods
        function obj = ConvPerceptron(filterSize, nfilter, nchannel, varargin)
            propmap = Config.parse(varargin{:});
            
            obj.conv = ConvTransform(filterSize, nfilter, nchannel);
            obj.pool = MaxPool(Config.getValue(propmap, 'poolSize', 3));
            obj.act  = Activation(Config.getValue(propmap, 'activationType', 'ReLU'));
            
            Config.apply(obj, propmap);
            
            % initialize size description of sub-units
            obj.pool.inputSizeDescription = obj.conv.outputSizeDescription;
            obj.act.inputSizeDescription  = obj.pool.outputSizeDescription;
            obj.outputSizePattern = SizeDescription.getPattern( ...
                obj.conv.inputSizeDescription, obj.act.outputSizeDescription);
        end
    end
    
    properties
        conv, pool, act
    end
end
