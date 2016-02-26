classdef Momentum < handle
% MOMENTUM is an abstraction of Momentum optimization method used in neural
% network learning.

% MooGu Z. <hzhu@case.edu>
% 2 25, 2016

    properties
        alpha    = 0.9;
        epsilon  = 1e-3;
        tau      = 1e-2;
        tstable  = 1e5;
    end
    
    methods
        function [grad, buffer] = proc(obj, grad, buffer)
            if not(isfield(buffer, 'momentum'))
                buffer.momentum.velocity = 0;
                buffer.momentum.count    = 0;
            else
                buffer.momentum.count = buffer.momentum.count + 1;
            end
            
            if buffer.momentum.count < obj.tstable
                stepsize = obj.epsilon * ...
                    (1 - (1 - obj.tau) * (buffer.momentum.count / obj.tstable));
            else
                stepsize = obj.epsilon * obj.tau;
            end
            
            grad = obj.alpha * buffer.momentum.velocity + stepsize * grad;
            
            buffer.momentum.velocity = grad;
        end
    end
    
    methods
        function obj = Momentum(epsilon)
            if exist('epsilon', 'var')
                obj.epsilon = epsilon;
            end
        end
    end
end
