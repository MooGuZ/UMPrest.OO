function str = strcatby(strarr, symbol)
% STRCATBY concatenate strings in cell array with specified symbol
%
% [USAGE] str = strcatby(strarr, symbol)
%
% MooGu Z. <hzhu@case.edu>
% June 12, 2015 - Version 0.00 : initial commit

assert(iscell(strarr), 'First argument needs to be a cell array of string.');

tmp = [strarr(:), cell(numel(strarr), 1)]';
tmp(2, 1 : end-1) = {symbol};
str = strcat(tmp{:});

end