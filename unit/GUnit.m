classdef GUnit < Connectable & Optimizable
% GUNIT is an abstraction of generative units.

% MooGu Z. <hzhu@case.edu>
% Feb 29, 2016

    methods (Abstract)
        data  = proc(obj, param)
        param = invp(obj, data)
        delta = bprop(obj, delta)
    end
    
    properties
        I, O
        wspace
    end
end
