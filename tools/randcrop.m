function piece = randcrop(data, pieceSize)
% RANDCROP crop one piece of data with specified dimension randomly.
%
% PIECE = RANDCROP(DATA, PIECESIZE)
%
% MooGu Z. <hzhu@case.edu>
% Jun 3, 2015 - Version 0.00 : initial commit

dataSize = size(data);
assert(numel(dataSize) >= numel(pieceSize), ...
    'crop piece can not have more dimension than original data.');

% generate cell array of data ranges in each dimension
rangearr = cell(1, numel(dataSize));
for i = 1 : numel(pieceSize)
    startcrd = randi(dataSize(i) - pieceSize(i) + 1);
    rangearr{i} = startcrd : startcrd + pieceSize(i) - 1;
end
for i = numel(pieceSize) + 1 : numel(dataSize)
    rangearr{i} = 1 : dataSize(i);
end

piece = data(rangearr{:});

end
