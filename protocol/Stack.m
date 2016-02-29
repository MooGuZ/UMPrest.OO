% STACK is a simple implementation of stack STRUCTURE
% [API] push, pop, numel
% [INTERFACE]
%   tof = isqualified(obj, unit)
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015

% [Change Log]
% Nov 20, 2015 - initial commit

classdef Stack < handle
    % ================= API =================
    methods
        function push(obj, unit)
            assert(obj.isqualified(unit), ...
                'specified unit is not qualified for this stack');
            obj.stack{end + 1} = unit;
        end

        function unit = pop(obj)
            unit = obj.stack{end};
            obj.stack = obj.stack(1 : end - 1);
        end

        function n = numel(obj)
            n = numel(obj.stack);
        end
    end
    % ================= INTERFACE FOR SUBCLASS =================
    methods (Abstract, Access = protected)
        tof = isqualified(obj, unit)
    end
    % ================= DATA STRUCTURE =================
    properties
        stack = {};
    end
end
