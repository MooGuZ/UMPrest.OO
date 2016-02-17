function H = multimg(mat)
% MULTIMG shows muliple image at the same time. The first version only support
% gray-scale images store in a 3D matrix.
%
% MooGu Z. <hzhu@case.edu>
% Feb 14, 2016
    
% [TO-DO]
% 1. apply subaxis tech to create tight axes
% 2. add support to other image types (currently only gray images)
% 3. tweak color render method

[imgh, imgw, nimg] = size(mat); % get information of images
[nrow, ncol] = arrange(nimg);   % make arrangement of plots
% setup figure size
scnsz = get(0, 'screensize');
ratio = max([ ...
    1.5 * ncol * imgw / scnsz(3), ...
    1.5 * nrow * imgh / scnsz(4), ...
    1]);
figw = ncol * imgw / ratio;
figh = nrow * imgh / ratio;
H = figure('Position', [100, 100, figw, figh]);
% display each image
for i = 1 : nimg
    subplot(nrow, ncol, i);
    imagesc(mat(:, :, i));
    axis off
end

end
