% MODEL : Complex Generative Model on Transform2D dataset
% CODE  : 
%% check environment
ishpc = isunix && not(ismac);
%% load package to MATLAB search path
if ishpc
    addpath('/home/hxz244'); 
    pathLoader('umpoo');
end
%% model parameters
if ishpc
    nhidunit  = 1024;
    nepoch    = 40;
    nbatch    = 500;
    batchsize = 32;
    validsize = 128;
    taskdir   = fileparts(mfilename('fullpath'));
else
    nhidunit  = 1024;
    nepoch    = 3;
    nbatch    = 3;
    batchsize = 8;
    validsize = 32;
    taskdir   = pwd();
end
whitenSizeOut = 512;
initEstch = 1e-3;
%% environment parameters
istart  = 5e4;
taskid  = ['COMPGEN', num2str(nhidunit), 'TRANSFORM2D'];
savedir = fullfile(taskdir, 'records');
datadir = fullfile(taskdir, 'data');
namept  = [taskid, '-ITER%d-DUMP.mat'];
%% load dataset and parameter setup
dataset = Transform2D();
nframes = dataset.nframes;
framesize = dataset.framesize;
%% load statistic information
load(fullfile(datadir, 'statrans_transform2d.mat'));
% stunit = Interface.loaddump(stdump);
stunit = Interface.loaddump(stdump);
stunit.frozen = true;
stunit.compressOutput(whitenSizeOut);
stat = stunit.getKernel(framesize);
%% create/load units and model
if istart == 0
    model = GenerativeUnit(PolarCLT.randinit(nhidunit, whitenSizeOut));
else
    load(fullfile(savedir, sprintf(namept, istart)));
    % model = Interface.loaddump(modeldump);
    model = Interface.loaddump(modeldump);
end
model.kernel.useCOModelNormalization = true;
model.noiseStdvar = 0.3;
model.I{1}.objweight = sqrt(stat.pixelweight);
sparse = model.O{1}.addPrior('cauchy', 'stdvar', sqrt(2));
slow   = model.O{1}.addPrior('slow', 'stdvar', sqrt(2));
%% setup inference options
model.inferOption = struct( ...
    'Method',      'bb', ...
    'Display',     'off', ...
    'MaxIter',     40, ...
    'MaxFunEvals', 50);
%% create prevnet
stunit.appendto(dataset.data).aheadof(model);
prevnet = stunit;
%% create objectives
lossfun = Likelihood('mse', sqrt(stat.pixelweight * whitenSizeOut * nframes) / model.noiseStdvar);
lossfun.x.connect(model.I{1});
lossfun.ref.connect(stunit.O{1});
%% create task
task = GenerativeTask(taskid, taskdir, model, dataset, lossfun, model.O{1}, ...
    'prevnet', prevnet, 'iteration', istart);
%% setup optmizator
opt = HyperParam.getOptimizer();
opt.gradmode('basic');
opt.stepmode('adapt', 'estimatedChange', initEstch);
opt.enableRcdmode(3);
%% run task
task.run(nepoch, nbatch, batchsize, validsize);
