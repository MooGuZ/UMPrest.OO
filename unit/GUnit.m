classdef GUnit < Connectable & Optimizable
% GUNIT is an abstraction of generative units.

% MooGu Z. <hzhu@case.edu>
% Feb 29, 2016

    methods (Abstract)
        param = proc(obj, data)
        data  = invp(obj, param)
        delta = fprop(obj, delta)
    end
    
    properties
        I, O
        wspace
    end
end
