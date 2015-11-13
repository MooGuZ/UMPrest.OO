function ret = findSubField(root, fields)
% FINDSUBFIELD search sub-fields of a structure trying to match the fields
% name recursively.
%
% [USAGE] ret = findSubField(root, fields) returns the actual field names
%           (because fields name are compared on case insensitve manner).
%
% MooGu Z. <hzhu@case.edu>
% June 11, 2015 - Version 0.00 : initial commit

assert(iscell(fields) || ischar(fields), ...
    '<fields> needs to be a cell array of string or a string.');

% special case : only one element in fields
if iscell(fields) && numel(fields) == 1
    fields = fields{1};
end

% find name of subfields
subfields = fieldnames(root);

if ischar(fields) % case : direct sub-field
    % remove white space in the field
    fields = fields(fields ~= ' ');
    % try to find match
    match = find(strcmpi(fields, subfields));
    if ~isempty(match)
        ret = subfields(match);
        return
    end
else % case : multiple levels sub-fields
    % remove white space in the field
    fields{1} = fields{1}(fields{1} ~= ' ');
    % try to find match
    match = find(strcmpi(fields{1}, subfields));
    if ~isempty(match)
        ret = findSubField(root.(subfields{match}), fields(2:end));
        % compose result or return false
        if iscell(ret)
            ret = [subfields(match), ret];
            return
        end
    end
end

ret = false;

end
    
    