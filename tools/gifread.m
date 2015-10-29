function data = gifread(gifPath, idx)
% GIFREAD load gif file into matrix
%
% DATA = GIFREAD(GIFPATH, IDX) load gif data in file located at GIFPATH.
% IDX specify index of frame that would read in. DATA is a 3D matrix with
% axis corresponding to spatial-y, spatial-x and temporal coordinates.
% GIFREAD would convert color animation into gray-scale one.
%
% See also, gif2anim, anim2gif.
%
% MooGu Z. <hzhu@case.edu>
% May 21, 2015 - Version 0.00 : initial commit

if exist('idx','var')
    [I,cmap] = imread(gifPath,'gif',idx);
else
    [I,cmap] = imread(gifPath,'gif','Frames','all');
end

isz = size(I);
assert(isz(3)==1,'[GIF2ANIM] GIF file cannot be recognized!');

% Convert Color Map to YCbCr Space
cmap = rgb2gray(cmap);

% Reshape Index Matrix if necessary
I = reshape(I,isz([1,2,4]));
% Construct Frames
data = cmap(double(I)+1);

end