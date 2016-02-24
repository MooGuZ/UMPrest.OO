% LUNIT is an abstraction of learning units.
%
% MooGu Z. <hzhu@case.edu>
% 2016-02-18

classdef Unit < Connectable
    methods (Abstract)
        data  = proc(obj, data)
        delta = bprop(obj, delta, optimizer)
    end
    
    properties
        I, O                            % state of last input/output
        wspace                          % work space, to store temporal information
    end
end
