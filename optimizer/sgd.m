classdef SGD < handle
    % SGD implement stochastic gradient decent methods over LModels.
    
    % MooGu Z. <hzhu@case.edu>
    % Feb 19, 2016
    methods
        function [grad, buffer] = proc(obj, grad, buffer)
            if ~isfield(buffer, 'sgd')
                buffer.sgd.lrate = obj.lrate;
                buffer.sgd.count = 0;
            else
                buffer.sgd.count = buffer.sgd.count + 1;
            end
            
            if ~mod(buffer.sgd.count, obj.cycle)
                buffer.sgd.lrate = buffer.sgd.lrate * obj.downStep;
            end
                
            grad = buffer.sgd.lrate * grad;
        end
    end
    
    properties
        lrate = 1;
        cycle = 1000;
        downStep = 0.95;
    end
    
    methods
        function obj = SGD(lrate)
            if exist('lrate', 'var')
                obj.lrate = lrate;
            end
        end
    end
end


