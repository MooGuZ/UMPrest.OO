classdef Model < handle
% MODEL is the abstraction of models in learning theories. It always compose
% by fundamental units, such as perceptrons and convolutional layers. MODEL
% works like a container and superviser that make each units work properly,
% and provides user friendly interfaces to operate.

% MooGu Z. <hzhu@case.edu>
% 2 23, 2016

    methods (Abstract)
        dataout = proc(obj, datain)
        
        trainproc(obj, data)
        
        value = objective(obj, y, ref)
    end
    
    properties
        optimizer
        I, O
    end
end

