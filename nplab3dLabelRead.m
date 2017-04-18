function label = nplab3dLabelRead(dataPath)
% NPLAB3DLABELPATTERN interprets file name of each video in NPLab3D dataset
[~, fname, ~] = fileparts(dataPath);
pattern = '.*_\d+-\d+_\d+_(\d+)_\d+';
token = regexp(fname, pattern, 'tokens');
label = str2double(token{1}{1}) + 1;