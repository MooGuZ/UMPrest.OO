% STACK is a simple implementation of stack STRUCTURE
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015

classdef Stack
    % ================= API =================
    methods (Static)
        function S = push(S, el)
            S = {S{:}, el};
        end

        function el = pop(S)
            el = S{end};
            S  = S(1 : end-1);
        end

        function value = size(S)
            value = numel(S);
        end
    end
end
