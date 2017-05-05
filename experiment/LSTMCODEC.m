%% BEGIN
taskid  = 'LSTMCODEC';
taskdir = abspath('~/Desktop/experiment');
savedir = fullfile(taskdir, 'records');
datadir = fullfile(taskdir, 'data');
istart  = 0;
namept  = [taskid, '-ITER%d-DUMP.mat'];
%% model parameters
sizein  = 1024;
sizeout = 1024;
nframes = 30;
%% create/load units and model
if istart == 0
    encoder = PHLSTM.randinit(sizein, sizeout);
    decoder = PHLSTM.randinit(sizein, sizeout);
    encoder.setupOutputMode('last');
    decoder.enableSelfeed(nframes - 1);
    encoder.aheadof(decoder);
    model = Model(encoder, decoder);
else
    load(fullfile(savedir, sprintf(namept, istart)));
    model = Evolvable.loaddump(modeldump);
end
%% create side path
reverser = FrameReorder('reverse');
reshaper = Reshaper().appendto(reverser);
sidepath = Model(reverser, reshaper);
%% create objectives
objective = Likelihood('mse');
%% load dataset
load(fullfile(datadir, 'NPLab3D.mat'));
nplab3d.enableSliceMode(nframes);
%% connect units to dataset and objective
nplab3d.data.connect(model.I{1});
nplab3d.data.connect(sidepath.I{1});
objective.x.connect(model.O{1});
objective.ref.connect(sidepath.O{1});
%% create task
task = CustomTask(taskid, taskdir, model, nplab3d, objective, {}, ...
    'sidepath', sidepath, '-nosave');
%% run task
task.run(10, 10, 16, 64);