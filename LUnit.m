% LUNIT is an abstraction of learning units.
%
% MooGu Z. <hzhu@case.edu>
% 2016-02-18

classdef LUnit < handle
    % ============= INTERFACE =============
    methods
        function connect(obj, otherUnit)
            if dimatch(obj.dimout(), otherUnit.dimin())
                obj.prev = otherUnit;
                otherUnit.next = obj;
            else
                error('LUNIT:CONNECTFAILED', ...
                      'Connection between units %s to %s failed.', ...
                      obj, otherUnit);
            end
        end
    end
    
    % ============= DATA & PROPERTY =============
    properties
        prev, next                      % points to previous/next unit
    end
    properties (Abstract)
        I, O                            % state of last input/output
    end
    methods (Abstract)
        dimin, dimout                   % diminionality of input/output
    end
end
