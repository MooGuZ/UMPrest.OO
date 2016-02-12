% Perceptron is an abstraction of full connected layer in neural network
%
% MooGu Z. <hzhu@case.edu>
% Feb 11, 2016
classdef Perceptron < handle & UtilityLib
    % ================= API =================
    methods
        function output = feedforward(obj, input)
            output = obj.afun(obj.W * input + obj.B);
            obj.I = input; obj.O = output;
        end
        
        function deriv = backpropagate(obj, deriv, stepSize)
            dB = deriv .* obj.dfun(obj.O);
            dW = dB * obj.I';
            deriv = obj.W' * dB;
            
            obj.W = obj.W - stepSize * dW;
            obj.B = obj.B - stepSize * dB;
        end
    end
    
    % ================= DATA & FIELD =================
    properties
        W % weight matrix
        B % bias vector
        I % input states
        O % output states
    end
    properties (Access = private)
        atype % type of activation (string)
        afun  % activate function handle
        dfun  % derivative of activation function 
    end
    properties (Dependent)
        activateType
        dimin
        dimout
    end
    methods
        function value = get.activateType(obj)
            value = lower(obj.atype);
        end
        function set.activateType(obj, value)
            switch lower(value)
              case {'sigmoid', 'logistic'}
                obj.afun = @(x) 1 ./ (1 + exp(-x));
                obj.dfun = @(x) x .* (1 - x);
              otherwise
                warning('Unrecognized activation type');
            end
        end
        
        function value = get.dimin(obj)
            value = size(obj.W, 2);
        end
        
        function value = get.dimout(obj)
            value = size(obj.W, 1);
        end
    end
    
    % ================= CONSTRUCTOR =================
    methods
        function obj = Perceptron(inSize, outSize, activateType, varargin)
            obj.W = (rand(outSize, inSize) - 0.5) * (2 / sqrt(inSize));
            obj.B = zeros(outSize, 1);
            obj.activateType = activateType;
            obj.setupByArg(varargin{:});
        end
    end
end

