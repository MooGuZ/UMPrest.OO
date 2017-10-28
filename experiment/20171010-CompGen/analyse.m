% MODEL : Separated Recurrent Model on NPLab3D dataset
% CODE  : 
%% model parameters
nhidunit = 1024;
validsize = 8;
whitenSizeOut = 512;
%% enviroment variables
istart  = 5e5;
taskid  = ['COMPGEN', num2str(nhidunit), 'TRANSFORM2D'];
taskdir = pwd();
savedir = fullfile(taskdir, 'records');
datadir = fullfile(taskdir, 'data');
plotdir = fullfile(taskdir, 'fig');
namept  = [taskid, '-ITER%d-DUMP.mat'];
%% load dataset and parameter setup
dataset = Transform2D();
framesize = dataset.framesize;
%% load statistic information
load(fullfile(datadir, 'statrans_transform2d.mat'));
stunit = Interface.loaddump(stdump);
stunit.frozen = true;
stunit.compressOutput(whitenSizeOut);
stat = stunit.getKernel(framesize);
%% load units and model
load(fullfile(savedir, sprintf(namept, istart)));
model = Interface.loaddump(modeldump);
model.I{1}.objweight = stat.pixelweight;
sparse = model.O{1}.addPrior('cauchy', 'scale', 10, 'stdvar', 0.4);
slow   = model.O{1}.addPrior('slow', 'stdvar', sqrt(2));
% model.kernel.useCOModelNormalization = true;
model.frozen = true;
%% setup inference option
model.inferOption = struct( ...
    'Method',      'bb',  ...
    'Display',     'iter', ...
    'MaxIter',     30,    ...
    'MaxFunEvals', 1e4);
%% create prevnet
stunit.appendto(dataset.data).aheadof(model);
prevnet = stunit;
%% create objectives
lossfun = Likelihood('mse', stat.pixelweight * sqrt(whitenSizeOut * validsize));
lossfun.x.connect(model.I{1});
lossfun.ref.connect(stunit.O{1});
%% reconstruction process
% dpkg = dataset.next(validsize);
wpkg = prevnet.forward(dpkg);
[alpha, phi] = model.forward(wpkg);
rwpkg = model.backward(alpha, phi);
rpkg  = prevnet.backward(rwpkg);
%% calculate objectives
likelihood = lossfun.evaluate(rwpkg, wpkg);
sparsePrior = sparse.evaluate(model.O{1}.data);
slowPrior   = slow.evaluate(model.O{1}.data);
fprintf('[Reconstruction] Likelihood : %.2e | Sparse : %.2e | Slow : %.2e\n', ...
    likelihood, sparsePrior, slowPrior);
%% show animation
animview({dpkg, rpkg});
%% save animations
% save(fullfile(plotdir, [taskid, '-ITER', num2str(istart), '-Sample.mat']), ...
%     'animorg', 'animref', 'animpred', '-v7.3');

