classdef SGD < Optimizer
    % SGD implement stochastic gradient decent methods over LModels.
    
    % MooGu Z. <hzhu@case.edu>
    % Feb 19, 2016
    methods
        function [grad, wspace] = proc(obj, grad, wspace)
            if ~isfield(wspace, 'sgd')
                wspace.sgd.lrate = obj.lrate;
                wspace.sgd.count = 1;
            end
            
            grad = wspace.sgd.lrate * grad;
            wspace.sgd.count = wspace.sgd.count + 1;
        end
    end
    
    properties
        lrate = 10^-4;
    end
end


