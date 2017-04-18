%% environment setup
datasize = 1024;
cellsize = 1024;
validsize = 128;
% load dataset
load('~/Desktop/NPLab3DMotion-ImageSequenceSet.mat');
nplab3d.enableFrameMode('shift', 1);
% create LSTM model
model = LSTM.randinit(datasize, cellsize);
% create objective 
likelihood = Likelihood('tmse', 2);
% create validate set
[validset.data, validset.label] = nplab3d.next(validsize);
% create initial state
validZeroPack = DataPackage(Tensor(zeros(cellsize, validsize)).get(), 1, false);
% display current status of estimation
objval = likelihood.evaluate(model.forward( ...
    validset.data.vectorize(), validZeroPack, validZeroPack).data, ...
    validset.label.vectorize().data);
fprintf('[%s] Initial objective value : %.2e\n', datestr(now), objval);
%% main loop
nepoch = 10;
batchsize = 16;
batchPerEpoch = 500;
zeropack = DataPackage(Tensor(zeros(cellsize, batchsize)).get(), 1, false);
for epoch = 1 : nepoch
    for i = 1 : batchPerEpoch
        [data, label] = nplab3d.next(batchsize);
        predict = model.forward(data.vectorize(),zeropack, zeropack);
        model.backward(likelihood.delta(predict, label.vectorize()));
        model.update();
    end
    niter = epoch * batchPerEpoch;
    objval = likelihood.evaluate( ...
        model.forward(validset.data, validZeroPack, validZeroPack).data, ...
        validset.label.data);
    fprintf('[%s] Objective Value after [%04d] iterations : %.2e\n', ...
        datestr(now), niter, objval);
    save(['~/Desktop/LSTM-SAVE/LSTM-ITER', num2str(niter), '.mat'], ...
        'model', '-v7.3');
end
%% generate random sample
nsample = 1;
[data, label] = nplab3d.next(nsample);
zeropack = DataPackage(Tensor(zeros(cellsize, nsample)).get(), 1, false);
predict = model.forward(data.vectorize(), zeropack, zeropack);
animcompare(label, predict);