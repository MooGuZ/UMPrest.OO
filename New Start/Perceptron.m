classdef Perceptron < EvolvingUnit
    methods
        function y = transproc(obj, x)
            y = obj.act.transform(obj.linproc.transform(x));
        end
        
        function d = errprop(obj, d)
            d = obj.linproc.errprop(obj.act.errprop(d));
        end
        
        function update(obj)
            obj.linproc.update();
        end
    end
    
    methods
        function sz = size(obj)
            sz = size(obj.linproc);
        end
    end
    
    methods
        function obj = Perceptron(inputSize, outputSize, varargin)
            obj.linproc = LinearTransform(inputSize, outputSize);
            obj.act     = Activation(Config.getValue(varargin, 'ActType', 'ReLU'));
        end
    end
    
    properties
        linproc
        act
    end
    
    properties (Dependent)
        actType
    end
    methods
        function value = get.actType(obj)
            value = obj.act.actType;
        end
        function set.actType(obj, value)
            obj.act.actType = value;
        end
    end
end
