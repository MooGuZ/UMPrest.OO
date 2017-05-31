% load dataset
load('~/Desktop/NPLab3DMotion-ImageSequenceSet-New.mat');
nplab3d.shiftFrames(1);
% create objective 
likelihood = Likelihood('tmse', 2);
% create validate set
validsize = 128;
[validset.data, validset.label] = nplab3d.next(validsize);
validset.data.vectorize();
validset.label.vectorize();
%% load Complex Bases learned by COModel
load ~/Dropbox/Record/comodel/20150929-NPLab3D/final-03OCT2015.mat
% get weight (real/imag weight and bias)
W = m.dewhitenMatrix * m.A;
B = m.imageMean;
% assign size information
datasize = numel(B);
cellsize = datasize;
%% compose generative process
genproc = BilinearTransform(real(W), imag(W), B);
% freeze this generative process
genproc.freeze();
% compose RecCO unit
model = RecCO( ...
    LinearTransform.randinit(2 * datasize, cellsize), ...
    LinearTransform.randinit(2 * datasize, cellsize), ...
    LinearTransform.randinit(2 * datasize, cellsize), ...
    LinearTransform.randinit(2 * datasize, cellsize), ...
    LinearTransform.randinit(2 * datasize, cellsize), ...
    LinearTransform.randinit(2 * datasize, cellsize), ...
    genproc, ...
    LinearTransform.randinit(2 * datasize, datasize));
%% display current status of estimation
objval = likelihood.evaluate(model.forward(validset.data).data, ...
    validset.label.data);
fprintf('[%s] Initial objective value : %.2e\n', datestr(now), objval);
%% optimization loop
nepoch = 20;
batchsize = 16;
batchPerEpoch = 1;
for epoch = 1 : nepoch
    for i = 1 : batchPerEpoch
        [data, label] = nplab3d.next(batchsize);
        predict = model.forward(data.vectorize());
        model.backward(likelihood.delta(predict, label.vectorize()));
        model.update();
    end
    niter = epoch * batchPerEpoch;
    objval = likelihood.evaluate(model.forward(validset.data).data, ...
        validset.label.data);
    fprintf('[%s] Objective Value after [%04d] iterations : %.2e\n', ...
        datestr(now), niter, objval);
end
