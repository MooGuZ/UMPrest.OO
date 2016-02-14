% MATFLIP flip matrix both in vertical and horizontal direction.
%
% MooGu Z. <hzhu@case.edu>
% Feb 13, 2016
function fmat = matflip(mat)
[r, c, ~] = size(mat);
fmat = mat(r : -1 : 1, c : -1 : 1, :);
end
