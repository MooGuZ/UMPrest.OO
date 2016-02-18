% ITE is short for if-then-else.
%
% ITE is mimicking operation ()?():() in C.
%
% MooGu Z. <hzhu@case.edu>
% Feb 18, 2016

function value = ite(cond, a, b)
if (cond)
    value = a;
else
    value = b;
end
end
