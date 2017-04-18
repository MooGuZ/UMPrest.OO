% setup parameter
taskcode   = 'CONVOPNEW';
startIter  = 10000;
nepoch     = 10;
batchsize  = 1;
validsize  = 1;
batchPerEpoch = 1000;
% setup task paramters
nfrmin  = 3;
nfrmout = 3;
fltsize = [4, 4];
frmsize = [32, 32];
% solve locations
homepath = fileparts(mfilename('fullpath'));
savepath = fullfile(homepath, 'records');
namePattern = [taskcode, '-ITER%d-DUMP.mat'];
% % load environment and librarys
% addpath('/home/hxz244/'); pathLoader('umpoo');
% % initialize LSTM model
% load(fullfile(savepath, sprintf(namePattern, startIter)));
% model = Evolvable.loaddump(modeldump);
% create objective 
likelihood = Likelihood('mse');
% initialize dataset
smg = SimpleAnimationGenerator();
smg.nframes = nfrmin;
smg.frameSize = frmsize;
smg.enablePredmode(nfrmout, fltsize);
% build/load model
tfltsize = [fltsize, nfrmin, nfrmout];
if startIter > 0
    load(fullfile(savepath, sprintf(namePattern, startIter)));
    cunit = Evolvable.loaddump(cunitdump);
    lunit = Evolvable.loaddump(lunitdump);
else
    cunit = ConvNet.randinit(nfrmin, [nfrmin * 2, nfrmin * 4, nfrmin * nfrmout], ...
        'poolsize', [2,2], 'OutputLayerActType', 'ReLU');
    lunit = LinearTransform.randinit(prod(tfltsize), prod(tfltsize));
%     lunit = MLP.randinit(prod(tfltsize), [2, 4, 1] * prod(tfltsize));
end
aunit = Activation('sigmoid');
convop = ConvOperator();
% setup optimizer
opt = HyperParam.getOptimizer();
opt.gradmode('basic');
opt.stepmode('adapt', 'estimatedChange', 1e-2);
% opt.enableRcdmode(3);
% create validate set
[validset.data, validset.label, ~] = smg.next(validsize);
validset.data.tcombine();
validset.label.tcombine();
% do prediction
predict.label = convop.forward(validset.data, aunit.forward(lunit.forward( ...
    cunit.forward(validset.data))).reshape(tfltsize));
% predict.filter = lunit.forward(cunit.forward(validset.data)).reshape(tfltsize);
% predict.label  = convop.forward(validset.data, predict.filter).tsplit();
% display current status of estimation
objval = likelihood.evaluate(predict.label.data, validset.label.data);
fprintf('[%s] Initial objective value : %.2e\n', datestr(now), objval);
% opt.record(objval, false);
% main loop
for epoch = 1 : nepoch
    for i = 1 : batchPerEpoch
        [data, label, ~] = smg.next(batchsize);
        data.tcombine();
        label.tcombine();
        
        predict.filter = aunit.forward(lunit.forward( ...
            cunit.forward(data))).reshape(tfltsize);
        predict.label = convop.forward(data, predict.filter);
%         predict.filter = lunit.forward(cunit.forward(data)).reshape(tfltsize);
        
        [~, delta] = convop.backward(likelihood.delta(predict.label, label));
        delta = aunit.backward(delta.vectorize());
        delta = lunit.backward(delta).reshape([fltsize, nfrmin * nfrmout]);
        cunit.backward(delta);
        
        lunit.update();
        cunit.update();
    end
    niter = startIter + epoch * batchPerEpoch;
    predict.label = convop.forward(validset.data, aunit.forward(lunit.forward( ...
        cunit.forward(validset.data))).reshape(tfltsize));
%     predict.filter = lunit.forward(cunit.forward(validset.data)).reshape(tfltsize);
    objval = likelihood.evaluate(predict.label.data, validset.label.data);
    fprintf('[%s] Objective Value after [%04d] iterations : %.2e\n', ...
        datestr(now), niter, objval);
    % opt.record(objval, false);
    cunitdump = cunit.dump();
    lunitdump  = lunit.dump();
    save(fullfile(savepath, sprintf(namePattern, niter)), 'cunitdump', 'lunitdump', '-v7.3');
end
% delete temporary saves
for epoch = 1 : nepoch - 1
    niter = startIter + epoch * batchPerEpoch;
    delete(fullfile(savepath, sprintf(namePattern, niter)));
end
% END
