function data = datafmt(data, dim)
% DATAFMT ensure data follow a specific format (dimension requirement). This
% function would reshape data when necessary. If reshape is not possible would
% throw an error.
%
% NOTE : this function is a tool specified for UMPrest.OO, may not have general
% usage in other environment.

% MooGu Z. <hzhu@case.edu>
% Feb 27, 2016

if isstruct(data)
    data = data.x;
end

if numel(data) == prod(dim)
    data = reshape(data, dim);
else
    error('[DATAFMT] data cannot achieve the requirement of object.');
end
