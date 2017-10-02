% MODEL : Separated Recurrent Model on NPLab3D dataset
% CODE  : 
%% model parameters
nbases   = 1024;
nhidunit = 1024;
nframeEncoder = 15;
nframePredict = 15;
%% enviroment variables
istart  = 10e3;
taskid  = ['DPHLSTM', num2str(nhidunit), 'NPLAB3D'];
taskdir = pwd();
savedir = fullfile(taskdir, 'records');
datadir = fullfile(taskdir, 'data');
plotdir = fullfile(taskdir, 'fig');
namept  = [taskid, '-ITER%d-DUMP.mat'];
%% load dataset and parameter setup
load(fullfile(datadir, 'nplab3d.mat'));
framesize = nplab3d.stat.smpsize;
npixel    = prod(framesize);
%% load COModel bases
comodel = load(fullfile(datadir, 'comodel_nplab3d.mat'));
% create whitening module
whitening = StatisticTransform('whiten', nplab3d.stat).appendto(nplab3d.data);
stat      = whitening.getKernel(framesize);
%% load model
load(fullfile(savedir, sprintf(namept, istart)));
encoder     = Interface.loaddump(encoderdump);
predict     = Interface.loaddump(predictdump);
reTransform = Interface.loaddump(retransformdump);
imTransform = Interface.loaddump(imtransformdump);
% connection LSTMs
encoder.stateAheadof(predict);
% create assistant units
crdTransform = Cart2Polar().appendto( ...
    reTransform, imTransform).aheadof(encoder.DI{1}, encoder.DI{2});
% build model
model = Model(reTransform, imTransform, crdTransform, encoder, predict);
%% create prevnet
inputSlicer  = FrameSlicer(nframeEncoder, 'front', 0).appendto( ...
    whitening).aheadof(reTransform).aheadof(imTransform);
outputSlicer = FrameSlicer(nframePredict, 'front', nframeEncoder).appendto(whitening);
prevnet = Model(whitening, inputSlicer, outputSlicer);
%% create postnet
ampact = SimpleActivation('ReLU').appendto(predict.DO{1});
angact = SimpleActivation('tanh').appendto(predict.DO{2});
angscaler = Scaler(pi).appendto(angact);
cotransform = PolarCLT(comodel.rweight, comodel.iweight, zeros(stat.sizeout, 1)).appendto( ...
    ampact, angscaler);
recompModel = LinearTransform(stat.decode, stat.offset(:)).appendto(cotransform);
recompRefer = LinearTransform(stat.decode, stat.offset(:)).appendto(outputSlicer);
postnet = Model(ampact, angact, angscaler, cotransform, recompModel, recompRefer);
%% create zero generators
zerogen = DataGenerator('zero', nhidunit, 'tmode', nframeEncoder);
zerogen.data.connect(predict.DI{1});
zerogen.data.connect(predict.DI{2});
errgen = DataGenerator('zero', nhidunit, 'tmode', nframeEncoder, '-errmode');
errgen.data.connect(encoder.DO{1});
errgen.data.connect(encoder.DO{2});
%% get test sample
nplab3d.next(8);
zerogen.next(8);
prevnet.forward();
model.forward();
postnet.forward();
%% show results
animorg  = nplab3d.data.packagercd;
animref  = recompRefer.O{1}.packagercd.reshape(framesize);
animpred = recompModel.O{1}.packagercd.reshape(framesize);
animview({animref, animpred});
%% save animations
% save(fullfile(plotdir, [taskid, '-ITER', num2str(istart), '-Sample.mat']), ...
%     'animorg', 'animref', 'animpred', '-v7.3');

