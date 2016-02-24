function str = var2str(var)
% VARSTR is a helper function convert variable into a descriptional string
%
% USAGE : STR = VAR2STR(VAR)
%
% MooGu Z. <hzhu@case.edu>
% Jul 03, 2015

% CHANGE LOG
% Jul 03, 2015 - Version 0.00 : initial commit

if (isnumeric(var) || islogical(var)) && (numel(var) == 1)
    str = num2str(var);
elseif ischar(var)
    str = var;
elseif numel(var) <= 3
    str = sprintf('%s %s', mat2str(var), class(var));
else
    str = sprintf('%s %s', strrep(mat2str(size(var)), ' ', 'X'), class(var));
end

end
