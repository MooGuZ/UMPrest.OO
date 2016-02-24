classdef Perceptron < Unit & Activation & UtilityLib
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
            input  = input(:);            
            output = obj.act.proc(obj.W * input + obj.B);
            
            obj.I = input; 
            obj.O = output;
        end
        
        function delta = bprop(obj, delta, optimizer)
            dB = delta .* obj.act.derv(obj.O);
            dW = dB * obj.I';
            delta = obj.W' * dB;
            
            [dW, obj.wspace.w] = optimizer.proc(dW, obj.wspace.w);
            [dB, obj.wspace.b] = optimizer.proc(dB, obj.wspace.b);
            
            obj.W = obj.W - dW;
            obj.B = obj.B - dB;
        end
    end
    
    % ============= CONNECTABLE IMPLEMENTATION =============
    methods    
        function value = dimin(obj, ~)
            value = size(obj.W, 2);
        end
        
        function value = dimout(obj, ~)
            value = size(obj.W, 1);
        end
        
        function tof = connect(self, other)
            dim = other.dimout();
            if prod(dim) ~= 0 && prod(dim) ~= self.dimin()
                tof = false;
                return
            end
            self.prev = other;
            other.next = self;
            tof = true;
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
            % initialize work space
            obj.wspace.w = struct();
            obj.wspace.b = struct();
        end
    end
end

