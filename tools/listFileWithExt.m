function fileList = listFileWithExt(path, varargin)
% LISTFIELWITHEXT would list all files with specified extention (start with
% '.'. This function would return all non-hidden files under specified path
% by default if no extention is specified.
%
% MooGu Z. <hzhu@case.edu>
%
% [CHANGE LOG]
% Nov. 4, 2015 - initial commit

animExtSet = varargin;
% fetch all files information under the folder
fileList = dir(path);
% initialize animation file index
findex = false(1,numel(fileList));
% search for files according to <animExtSet>
for i = 1 : numel(fileList)
    % ignore hidden file and folders, including '.' and '..'
    if fileList(i).name(1) == '.', continue; end
    % skip directories (no recurvely search)
    if fileList(i).isdir, continue; end
    % pick out animation files
    [~,~,ext] = fileparts(fileList(i).name);
    if isempty(animExtSet) || any(strcmpi(ext,animExtSet))
        findex(i) = true;
    end
end
% filter file name list
fileList = {fileList(findex).name};

end