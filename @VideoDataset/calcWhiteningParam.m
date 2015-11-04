function calcWhiteningParam(obj)

% % convert data into format DOUBLE
% data = obj.fetch();
% obtain data samples to calculate whitening parameters
if obj.enableCrop
    data = obj.next( ...
        round(obj.whiteningSampleRatio * obj.patchPerBlock * numel(obj.dataFileIDList)));
else
    data = obj.next(round(obj.whiteningSampleRatio * numel(obj.dataFileIDList)));
end
% bias : mean vector of all video frames
obj.biasVector = mean(data, 2);
% variance : variance of noise values accross all frames
noiseVar = var(data(:)) * obj.whiteningNoiseRatio;
% covariance matrix of all frames
covMatrix = data * data'; clear data;
% principle components analysis
[eigVec, eigVal] = eig(covMatrix);
[eigVal, index]  = sort(diag(eigVal), 'descend');
eigVec = eigVec(:, index);
% calculate cutoff value of variance
varCutoff = obj.whiteningCutoffRatio * noiseVar;
% select eligible components
iCutoff = sum(eigVal > varCutoff);
eigVal = eigVal(1 : iCutoff);
eigVec = eigVec(:, 1 : iCutoff);
% compose encode/decode matrix
obj.whiteningEncodeMatrix = diag(1 ./ sqrt(eigVal)) * eigVec';
obj.whiteningDecodeMatrix = eigVec * diag(eigVal);
obj.whiteningZeroPhaseMatrix = eigVec * diag(1 ./ sqrt(eigVal)) * eigVec';
% calculate scale factor of each component with a rolloff mask
iRolloff = sum(eigVal > varCutoff * obj.whiteningRolloffFactor);
obj.whiteningNoiseFactor = ones(iCutoff, 1);
obj.whiteningNoiseFactor(iRolloff+1 : end) = 0.5 * (1 + cos( linspace(0, pi, iCutoff - iRolloff)));
obj.whiteningNoiseFactor = obj.whiteningNoiseFactor / obj.whiteningNoiseRatio;

% mark activation of whitening process
obj.whiteningIsActivated = true;

end
