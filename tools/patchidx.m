function idx = patchidx(fsize, psize)
% PATCHIDX returns index of elements in the first patch of a frame.
% 
% Usage:
%   IDX = PATCHIDX(FSIZE, PSIZE) returns the index of elements under condition that
%   patch size is PSIZE, while frame size is FSIZE.

% MooGu Z. <hzhu@case.edu>
% Mar 24, 2016

assert(numel(fsize) == numel(psize), 'ArgumentError:PATCHIDX', ...
       'Frame and patch should in same dimension.');

switch numel(fsize)
  case 0
    error('ArgumentError:PATCHIDX', 'Given size information is illeagal.');
    
  case 1
    idx = (1 : psize)';
    
  case 2
    idx = 1 : prod(fsize);
    idx = reshape(idx, fsize);
    idx = idx(1 : psize(1), 1 : psize(2));
    
  case 3
    idx = 1 : prod(fsize);
    idx = reshape(idx, fsize);
    idx = idx(1 : psize(1), 1 : psize(2), 1 : psize(3));
    
  otherwise
    step = [1, cumprod(fsize(1 : end - 1))];
    idx  = ones(psize);
    for i = 1 : numel(psize)
        v = step(i) * (0 : psize(i) - 1);
        s = ones(1, numel(psize));
        s(i) = psize(i);
        idx = bsxfun(@plus, idx, reshape(v, s));
    end
end
