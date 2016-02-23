classdef SGD
    % SGD implement stochastic gradient decent methods over LModels.
    
    % MooGu Z. <hzhu@case.edu>
    % Feb 19, 2016
    methods
        function [grad, wspace] = proc(obj, grad, wspace)
            if ~isfield(wspace, 'lrate')
                wspace.lrate = obj.lrate;
            end
            
            grad = wspace.lrate * grad;
        end
    end
    
    properties
        lrate = 10^-4;
    end
end


