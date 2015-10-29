function piece = crop(data, cropCrds)
% CROP crop one piece of data at specified coordinates. if original
% data has more dimension than the coordinates, the piece would
% extend in extra dimension by default.
%
% PIECE = CROP(DATA, CROPCRDS)
%
% MooGu Z. <hzhu@case.edu>
% Jun 3, 2015 - Version 0.00 : initial commit

assert(rem(numel(cropCrds),2) == 0, ...
    'coordinates pairs of crop region is incomplete.');

dataSize = size(data);
assert(numel(dataSize) >= numel(cropCrds)/2, ...
    'crop piece can not have more dimension than original data.');

% generate cell array of data ranges in each dimension
rangearr = cell(1, numel(dataSize));
for i = 1 : 2 : numel(cropCrds)
    rangearr{(i+1)/2} = cropCrds(i) : cropCrds(i+1);
end
for i = numel(cropCrds) / 2 + 1 : numel(dataSize)
    rangearr{i} = 1 : dataSize(i);
end

piece = data(rangearr{:});

end
