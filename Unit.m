% LUNIT is an abstraction of learning units.
%
% MooGu Z. <hzhu@case.edu>
% 2016-02-18

classdef Unit < DPModule
    % ============= INTERFACE =============
    methods
        function connect(obj, unit)
            if dimatch(obj.dimin(), unit.dimout())
                obj.prev = unit;
                unit.next = obj;
            else
                error('LUNIT:CONNECTFAILED', ...
                      'Connection between %s to %s failed.', ...
                      class(unit), class(obj));
            end
        end
    end
    
    % ============= DATA & PROPERTY =============
    properties (Abstract)
        prev, next                      % points to previous/next unit
    end
    properties (Abstract)
        I, O                            % state of last input/output
    end
end
