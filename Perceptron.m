classdef Perceptron < Unit
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

    % ============= LUNIT INTERFACE =============
    methods
        function output = proc(obj, input)
            output = obj.act.op(obj.W * input(:) + obj.B);
            obj.I = input; obj.O = output;
        end
        
        function delta = bprop(obj, delta, optimizer)
            dB = delta .* obj.activation.derv(obj.O);
            dW = dB * obj.I';
            delta = obj.W' * dB;
            
            [dW, obj.wspace.w] = optimizer.proc(dW, obj.wspace.w);
            [dB, obj.wspace.b] = optimizer.proc(dB, obj.wspace.b);
            
            obj.W = obj.W - dW;
            obj.B = obj.B - dB;
        end
        
        function value = dimin(obj)
            value = size(obj.W, 2);
        end
        
        function value = dimout(obj, ~)
            value = size(obj.W, 1);
        end         
    end
    
    % ================= DATA & PARAM =================
    properties
        W                               % weight matrix
        B                               % bias vector
        I                               % input states
        O                               % output states
        prev = nan;                     % previous unit
        next = nan;                     % next unit
        wspace                          % work space
    end
    properties
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
                obj.act.op   = @MathLib.sigmoid;
                obj.act.derv = @MathLib.sigmoid_derv;
              otherwise
                warning('Unrecognized activation type');
            end
        end        
    end
    
    % ================= CONSTRUCTOR =================
    methods
        function obj = Perceptron(dimin, dimout, activateType)
            if nargin > 0
                obj.W = (rand(dimout, dimin) - 0.5) * (2 / sqrt(dimin));
                obj.B = zeros(dimout, 1);
                if exist('activateType', 'var')
                    obj.activateType = activateType;
                else
                    obj.activateType = 'sigmoid';
                end
            end
            % initialize work space
            obj.wspace.w = struct();
            obj.wspace.b = struct();
        end
    end
end

