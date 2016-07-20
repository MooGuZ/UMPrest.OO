classdef Perceptron < MappingUnit
    methods
        function y = process(obj, x)
            y = obj.act.transform(obj.linproc.transform(x));
        end
        
        function d = errprop(obj, d, isEvolving)
            if exist('isEvolving', 'var')
                d = obj.linproc.errprop(obj.act.errprop(d), isEvolving);
            else
                d = obj.linproc.errprop(obj.act.errprop(d));
            end
        end
        
        function update(obj, stepsize)
            if exist('stepsize', 'var')
                obj.linproc.update(stepsize);
            else
                obj.linproc.update();
            end
        end
    end
    
    methods
        function unit = inverseUnit(obj) % TEMPORARY SOLUTION
            unit = Perceptron( ...
                double(obj.outputSizeDescription), ...
                double(obj.inputSizeDescription), ...
                'ActType', obj.act.actType);
        end
    end
    
    % ======================= SIZE DESCRIPTION =======================
    properties (Dependent)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(obj)
            value = obj.linproc.inputSizeDescription;
        end
        
        function descriptionOut = sizeIn2Out(obj, ~)
            descriptionOut = obj.act.outputSizeDescription;
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = Perceptron(inputSize, outputSize, varargin)
            obj.linproc = LinearTransform(inputSize, outputSize);
            obj.act     = Activation(Config.getValue(varargin, 'ActType', 'ReLU'));
            % setup size description
            obj.act.inputSizeDescription = obj.linproc.outputSizeDescription;
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties
        linproc, act
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
