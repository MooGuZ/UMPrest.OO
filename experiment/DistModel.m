% setup parameter
taskcode   = 'DISTMODEL';
startIter  = 0;
nepoch     = 10;
batchsize  = 16;
validsize  = 64;
batchPerEpoch = 100;
% setup task paramters
nfrmin  = 3;
nfrmout = 3;
psize   = [2, 2];
frmsize = [32, 32];
sizeout = prod([4, 4, nfrmout]);
ncategory = 5;
nbasis    = ceil(sizeout * 1.2);
% solve locations
homepath = fileparts(mfilename('fullpath'));
savepath = fullfile(homepath, 'records');
namePattern = [taskcode, '-ITER%d-DUMP.mat'];
% % load environment and librarys
% addpath('/home/hxz244/'); pathLoader('umpoo');
% create objective 
target = ObjSum();
% load dataset
% load('~/Desktop/testset.mat');
% build/load model
if startIter > 0
    load(fullfile(savepath, sprintf(namePattern, startIter)));
    cunit = Interface.loaddump(cunitdump);
    gunit = Interface.loaddump(gunitdump);
else
    cunit = ConvNet.randinit(nfrmin, [2 * nfrmin, 4 * nfrmin, nfrmout], ...
        'poolsize', psize, 'OutputLayerActType', 'Sigmoid');
    gunit = GaussianMixtureUnit(ncategory, nbasis, sizeout);
    gunit.A.prior = DistVar();
end
% aunit = Activation('sigmoid');
% setup optimizer
opt = HyperParam.getOptimizer();
opt.gradmode('basic');
opt.stepmode('adapt', 'estimatedChange', 1e-1);
opt.enableRcdmode(3);
% create validate set
[validset.data, validset.label] = nplab3d.next(validsize);
validset.data.tselectRandom(nfrmin).tcombine();
% display current status of estimation
objval = target.evaluate(gunit.forward(cunit.forward(validset.data), validset.label));
fprintf('[%s] Initial objective value : %.2e\n', datestr(now), objval);
opt.record(objval, false);
% main loop
for epoch = 1 : nepoch
    for i = 1 : batchPerEpoch
        [data, label] = nplab3d.next(batchsize);
        data.tselectRandom(nfrmin).tcombine();
        prob = gunit.forward(cunit.forward(data), label);

        cunit.backward(gunit.backward(target.delta(prob)).reshape([4, 4, nfrmout]));
        
        gunit.update();
        cunit.update();
    end
    niter = startIter + epoch * batchPerEpoch;
    objval = target.evaluate(gunit.forward(cunit.forward(validset.data), validset.label));
    fprintf('[%s] Objective Value after [%04d] iterations : %.2e\n', ...
        datestr(now), niter, objval);
    opt.record(objval, false);
    cunitdump = cunit.dump();
    gunitdump = gunit.dump();
    % save(fullfile(savepath, sprintf(namePattern, niter)), 'cunitdump', 'gunitdump', '-v7.3');
end
% delete temporary saves
% for epoch = 1 : nepoch - 1
%     niter = startIter + epoch * batchPerEpoch;
%     delete(fullfile(savepath, sprintf(namePattern, niter)));
% end
% END
