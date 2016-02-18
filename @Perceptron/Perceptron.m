% Perceptron is an abstraction of perceptron in brain.
% 
% PERCEPTRON is the base class of other kind of perceptrons, such as convolutional
% perceptrons. However, PERCEPTRON is not abstract. It represents the common
% full-connected model in neural network.
%
% MooGu Z. <hzhu@case.edu>
% Feb 11, 2016

% TO-DO
% 1. add more activation type

classdef Perceptron < handle & MathLib
    % ================= API =================
    methods
        function output = feedforward(obj, input)
            output = obj.act.op(obj.W * input(:) + obj.B);
            obj.I = input; obj.O = output;
        end
        
        function delta = backpropagate(obj, delta, optimp)
            dB = delta .* obj.activation.derv(obj.O);
            dW = dB * obj.I';
            delta = obj.W' * dB;
            
            obj.W = obj.W - optimp * dW;
            obj.B = obj.B - optimp * dB;
        end
    end
    
    % ================= DATA & PARAM =================
    properties
        W % weight matrix
        B % bias vector
        I % input states
        O % output states
    end
    properties (Access = private)
        act = struct('type', 'off', 'op', nan, 'derv', nan); % activation function
    end
    
    % ================= FUNCTIONAL PARAM =================
    properties (Dependent)
        activateType
    end
    methods
        function value = get.activateType(obj)
            value = obj.act.type;
        end
        function set.activateType(obj, value)
            switch lower(value)
              case {'sigmoid', 'logistic'}
                obj.act.type = lower(value);
                obj.act.op   = @obj.sigmoid;
                obj.act.derv = @obj.sigmoid_derv;
              otherwise
                warning('Unrecognized activation type');
            end
        end
    end
    
    % ================= CONSTRUCTOR =================
    methods
        function obj = Perceptron(dimin, dimout, activateType)
            obj.W = (rand(dimout, dimin) - 0.5) * (2 / sqrt(dimin));
            obj.B = zeros(dimout, 1);
            obj.activateType = activateType;
        end
    end
end

