% warning('off', 'MATLAB:singularMatrix');

taskid  = 'DISTMODEL';
% taskdir = fileparts(mfilename('fullpath'));
taskdir = abspath('~/Desktop/experiment');
savedir = fullfile(taskdir, 'records');
istart  = 0;
namept  = [taskid, '-ITER%d-DUMP.mat'];
% model parameters
nfrmin  = 3;
nfrmout = 3;
psize   = [2, 2];
frmsize = [32, 32];
sizeout = prod([4, 4, nfrmout]);
ncat    = 5;
nbasis  = ceil(sizeout * 1.2);
% create/load units and model
if istart == 0
    cunit   = ConvNet.randinit(nfrmin, [2 * nfrmin, 4 * nfrmin, nfrmout], ...
        'poolsize', psize, 'OutputLayerActType', 'tanh', 'HiddenLayerActType', 'tanh');
    gunit   = GaussianMixtureUnit.randinit(ncat, nbasis, sizeout);
    % dshaper = Reshaper().appendto(cunit).aheadof(gunit.apdata);
    % model   = Model(cunit, dshaper, gunit);
    model = DDModel(cunit, gunit);
else
    load(fullfile(savedir, sprintf(namept, istart)));
    model = Evolvable.loaddump(modeldump);
end
% create objectives
prob = ObjSum();
% load dataset
% nplab3d = ImageSequenceSet('~/Desktop/testset/', 'LabelReadFcn', @nplab3dLabelRead);
load('~/Desktop/NPLab3DMotion-WithLabel.mat');
nplab3d.enableSliceMode(nfrmin);
nplab3d.hideTAxis = true;
% connect units to dataset and objective
nplab3d.data.connect(model.I{1});
nplab3d.label.connect(model.I{2});
model.O{1}.connect(prob.x);
% get energy estimate of dataset
statinfo  = nplab3d.stat.fetch();
energyEst = sum(statinfo.std(:).^2);
% create priors
distinguish = DistVar(model.distUnit.A, 'scale', -0.01);
% entropy = Entropy(model.transUnit.O{1}, 'scale', 1);
keepenergy = KeepEnergy(model.transUnit.O{1}, energyEst, 'scale', 1);
% create task
task = CustomTask(taskid, taskdir, model, nplab3d, prob, {distinguish, keepenergy}, '-nosave');
% run task
task.run(10, 10, 16, 64);
