function cc = cellcomb(cellarr)
% CELLCOMB combine array of cell array into one cell array

% MooGu Z. <hzhu@case.edu>
% 3 22, 2016

cc = cell(1, sum(cellfun(@numel, cellarr)));

i = 0;
for j = 1 : numel(cellarr)
    cc(i + 1 : i + n) = cellarr{j}(:);
    i = i + n;
end
