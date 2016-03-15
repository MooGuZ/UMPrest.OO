function out = mtimesnd(mat, in)
% MTIMESND apply matrix multiplication to N-dimensional matrix.

% MooGu Z. <hzhu@case.edu>
% Feb 29, 2016

insz = size(in);
if numel(insz) < 3
    out = mat * in;
else
    out = mat * reshape(in, [insz(1), prod(insz(2:end))]);
    out = reshape(out, [size(out, 1), insz(2:end)]);
end
