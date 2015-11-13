function [keys, values] = propertyParse(varargin)
% PROPERTYPARSE return keys and values as cell arrays by parsing
% input property list, which should organized in key-value pairs,
% except switcher perperties, which just have keys initialized by
% '-'. For example, '-Approximate' means control field 'approximate'
% set to true.
%
% [KEYS, VALUES] = PROPERTYPARSE(PLIST)
%
% MooGu Z. <hzhu@case.edu>
% June 5, 2015 - Version 0.00 : initial commit

% initialize <keys> and <values>
keys   = cell(0);
values = cell(0);

index = 1;
nargs = numel(varargin);
% scan property list
while index <= nargs
    key = varargin{index};
    if key(1) == '-' % unary (switcher) property
        keys   = [keys, {key(2:end)}];
        values = [values, {true}];
        index = index + 1;
    else % binary (key-value pair) property
        assert(nargs >= index + 1, ...
            sprintf('value of binary property [%s] is missing.', key));
        keys   = [keys, {key}];
        values = [values, varargin(index + 1)];
        index = index + 2;
    end
end    

end
