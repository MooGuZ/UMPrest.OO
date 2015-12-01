% UWPHASE unwrap phases in [-pi,pi]
%
%   UNWRAP = uwphase(WRAPPED)
%
% MooGu Z. <hzhu@case.edu>
% Nov 30, 2015 - initial commit
function unwrap = uwphase(wrapped)
    unwrap = cumsum([wrapped(1), wrapToPi(diff(wrapped(:)'))]);
end
