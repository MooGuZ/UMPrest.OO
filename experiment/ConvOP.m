% setup parameter
taskcode   = 'CONVOPTEST';
startIter  = 0;
nepoch     = 10;
batchsize  = 16;
validsize  = 64;
batchPerEpoch = 100;
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
    cunit = Interface.loaddump(cunitdump);
    lunit = Interface.loaddump(lunitdump);
else
    cunit = ConvNet.randinit(nfrmin, [nfrmin * 2, nfrmin * 4, nfrmin * nfrmout], ...
        'poolsize', [2,2], 'OutputLayerActType', 'ReLU');
%     lunit = LinearTransform.randinit(prod(tfltsize), prod(tfltsize));
    lunit = MLP.randinit(prod(tfltsize), [2, 4, 1] * prod(tfltsize));
end
% aunit = Activation('sigmoid');
% setup optimizer
opt = HyperParam.getOptimizer();
opt.gradmode('basic');
opt.stepmode('adapt', 'estimatedChange', 1e-2);
opt.enableRcdmode(3);
% create validate set
[validset.data, ~, validset.filter] = smg.next(validsize);
validset.data.tcombine();
validset.filter.tcombine();
% do prediction
% predict.filter = aunit.forward(lunit.forward( ...
%     cunit.forward(validset.data))).reshape(tfltsize);
predict.filter = lunit.forward(cunit.forward(validset.data)).reshape(tfltsize);
% predict.label  = convop.forward(validset.data, predict.filter).tsplit();
% display current status of estimation
objval = likelihood.evaluate(predict.filter.data, validset.filter.data);
fprintf('[%s] Initial objective value : %.2e\n', datestr(now), objval);
opt.record(objval, false);
% main loop
for epoch = 1 : nepoch
    for i = 1 : batchPerEpoch
        [data, ~, filter] = smg.next(batchsize);
        data.tcombine();
        filter.tcombine();
        
%         predict.filter = aunit.forward(lunit.forward( ...
%             cunit.forward(data))).reshape(tfltsize);
        predict.filter = lunit.forward(cunit.forward(data)).reshape(tfltsize);
        
        delta = likelihood.delta(predict.filter, filter).vectorize();
%         delta = aunit.backward(delta);
        delta = lunit.backward(delta).reshape([fltsize, nfrmin * nfrmout]);
        cunit.backward(delta);
        
        lunit.update();
        cunit.update();
    end
    niter = startIter + epoch * batchPerEpoch;
%     predict.filter = aunit.forward(lunit.forward( ...
%         cunit.forward(validset.data))).reshape(tfltsize);
    predict.filter = lunit.forward(cunit.forward(validset.data)).reshape(tfltsize);
    objval = likelihood.evaluate(predict.filter.data, validset.filter.data);
    fprintf('[%s] Objective Value after [%04d] iterations : %.2e\n', ...
        datestr(now), niter, objval);
    opt.record(objval, false);
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
