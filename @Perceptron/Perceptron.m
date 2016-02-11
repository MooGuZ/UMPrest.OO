% Perceptron is an abstraction of full connected layer in neural network
%
% MooGu Z. <hzhu@case.edu>
% Feb 11, 2016
classdef Perceptron < handle
    % ================= API =================
    methods
        function output = feedforward(obj, input)
            output = obj.W * input + obj.B;
            obj.I = input; obj.O = output;
        end
        
        function deriv = backpropagate(obj, deriv, stepSize)
            dB = delta .* dfun(obj.O);
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
    end
    
    % ================= CONSTRUCTOR =================
    methods
        function obj = Perceptron(inSize, outSize, activateType, varargin)
            obj.W = randn(outSize, inSize);
            obj.B = randn(outSize, 1);
            obj.activateType = activateType;
            obj.setupByArg(varargin{:});
        end
    end
end

