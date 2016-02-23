% MATFLIP flip matrix both in vertical and horizontal direction.
%
% MooGu Z. <hzhu@case.edu>
% Feb 13, 2016
function fmat = matflip(mat)
fmat = reshape(mat(size(mat, 1) : -1 : 1, size(mat, 2) : -1 : 1, :), size(mat));
end
