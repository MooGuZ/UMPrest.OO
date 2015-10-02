function calcWhiteningParam(obj)

% convert data into format DOUBLE
data = obj.fetchData();
% bias : mean vector of all video frames
obj.biasVector = mean(data, 2);
% variance : variance of pixel values accross all frames
pixelVar = var(data(:));
% covariance matrix of all frames
covMatrix = data * data';
% principle components analysis
[eigVec, eigVal] = eig(covMatrix);
[eigVal, index]  = sort(diag(eigVal), 'descend');
eigVec = eigVec(:, index);
% calculate cutoff value of variance
varCutoff = obj.whiteningCutoffRatio * pixelVar;
% select eligible components
nComponent = sum(eigVal > varCutoff);
eigVal = eigVal(1 : nComponent);
eigVec = eigVec(:, 1 : nComponent);
% compose encode/decode matrix
obj.whiteningEncodeMatrix = diag(1 ./ sqrt(eigVal)) * eigVec';
obj.whiteningDecodeMatrix = eigVec * diag(eigVal);

% mark activation of whitening process
obj.whiteningIsActivated = true;

end
