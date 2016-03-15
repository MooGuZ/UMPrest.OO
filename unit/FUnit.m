classdef FUnit < Connectable & Optimizable
% FUNIT is an abstraction of feedforward units.
%
% See also, Perceptron, ConvPerceptron.

% MooGu Z. <hzhu@case.edu>
% 2016-02-18

    methods (Abstract)
        param = proc(obj, data)
        delta = bprop(obj, delta)
    end
    
    properties
        I, O                            % state of last input/output
        wspace                          % work space, to store temporal information
    end
end
