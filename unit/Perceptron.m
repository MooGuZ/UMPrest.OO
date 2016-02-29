classdef Perceptron < FUnit & Activation & UtilityLib
% Perceptron is an abstraction of perceptron in brain.
% 
% PERCEPTRON is the base class of other kind of perceptrons, such as convolutional
% perceptrons. However, PERCEPTRON is not abstract. It represents the common
% full-connected model in neural network.
%
% MooGu Z. <hzhu@case.edu>
% Feb 11, 2016

    % ============= UNIT IMPLEMENTATION =============
    methods
        function output = proc(obj, input)
            input  = datafmt(input, obj.dimin());
            output = obj.act.proc(obj.W * input + obj.B);
            
            obj.I = input; 
            obj.O = output;
        end
        
        function delta = bprop(obj, delta)
            delta = datafmt(delta, obj.dimout());
            
            dB = obj.act.bprop(delta);
            dW = dB * obj.I';
            
            delta = obj.W' * dB;
            
            obj.addGradient(dB, @obj.updateBias);
            obj.addGradient(dW, @obj.updateWeight);
            
            obj.optimize();
        end
    end
    
    % ============= CONNECTABLE IMPLEMENTATION =============
    methods    
        function value = dimin(obj)
            value = size(obj.W, 2);
        end
        
        function value = dimout(obj)
            value = size(obj.W, 1);
        end
    end
    
    % ============= ASSISTANT METHODS =============
    methods
        function updateBias(obj, delta)
            obj.B = obj.B - delta;
        end
        
        function updateWeight(obj, delta)
            obj.W = obj.W - delta;
        end
    end
    
    % ================= DATA & PARAM =================
    properties
        W                               % weight matrix
        B                               % bias vector
    end
    
    % ================= CONSTRUCTOR =================
    methods
        function obj = Perceptron(dimin, dimout, varargin)
            obj.setupByArg(varargin{:});
            % initialize weights and bias
            obj.W = (rand(dimout, dimin) - 0.5) * (2 / sqrt(dimin));
            obj.B = zeros(dimout, 1);
        end
    end
end

