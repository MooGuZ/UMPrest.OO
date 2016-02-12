% MLP (MutiLayer Perceptron) is the abstraction of multiple layer neural network
% model. 
%
% MooGu Z. <hzhu@case.edu> 
% Feb 11, 2016
classdef MLP < handle & UtilityLib
    properties
        debug = false;
    end
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function output = proc(obj, input)
            output = obj.feedfoward(input);
        end
    end
    
    % ================= LEARNINGMODULE IMPLEMENTATION =================
    methods
        function learn(obj, input, target, stepSize)
            output = obj.feedforward(input);
            deriv  = obj.derivative(output, target);
            obj.backpropagate(deriv, stepSize);
        end
    end
    
    % ================= ASSISTANT METHOD  =================
    methods
        function output = feedforward(obj, input)
            data = input;
            for i = 1 : numel(obj.Layer)
                data = obj.Layer{i}.feedforward(data);
            end
            output = data;
        end
        
        function backpropagate(obj, deriv, stepSize)
            for i = numel(obj.Layer) : -1 : 1
                deriv = obj.Layer{i}.backpropagate(deriv, stepSize);
            end
        end
        
        function value = objective(obj, output, target)
            value = target .* log(output) + (1 - target) .* log(1 - output);
            value = -sum(value(:)) / obj.dimout;
        end
        
        function deriv = derivative(obj, output, target)
            deriv = -(target ./ output - (1 - target) ./ (1 - output)) / obj.dimout;
        end
    end
    
    % ================= DATA & PARAM =================
    properties
        Layer
    end
    properties (Dependent)
        activateType
        dimin
        dimout
    end
    methods
        function value = get.activateType(obj)
            value = obj.Layer{1}.activateType;
            if obj.debug
                for i = 2 : numel(obj.Layer)
                    assert(strcmp(obj.Layer{i}.activateType, value));
                end
            end
        end
        function set.activateType(obj, value)
            for i = 1 : numel(obj.Layer)
                obj.Layer{i}.activateType = value;
            end
        end
        
        function value = get.dimin(obj)
            value = obj.Layer{1}.dimin;
        end
        
        function value = get.dimout(obj)
            value = obj.Layer{end}.dimout;
        end
    end
    
    % ================= Constructor =================
    methods
        function obj = MLP(layerSize, activateType, varargin)
            assert(numel(layerSize) > 2, 'MLP need more than two layers');
            
            obj.Layer = cell(numel(layerSize) - 1, 1);
            for i = 1 : numel(obj.Layer)
                obj.Layer{i} = Perceptron(layerSize(i), layerSize(i+1), ...
                                          activateType, varargin{:});
            end
            
            obj.setupByArg(varargin{:});
        end
    end
end
