taskid  = 'NEWDISTMODEL';
taskdir = fileparts(mfilename('fullpath'));
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
        'poolsize', psize, 'OutputLayerActType', 'Sigmoid');
    gunit   = GaussianMixtureUnit(ncat, nbasis, sizeout);
    dshaper = Reshaper().appendto(cunit).aheadof(gunit.apdata);
    model   = Model(cunit, dshaper, gunit);
else
    load(fullfile(savedir, sprintf(namept, istart)));
    model = Evolvable.loaddump(modeldump);
end
% create objectives
prob = ObjSum();
% load dataset
nplab3d = ImageSequenceSet('~/Desktop/testset/', 'LabelReadFcn', @nplab3dLabelRead);
nplab3d.enableSliceMode(nfrmin);
nplab3d.hideTAxis = true;
% connect units to dataset and objective
nplab3d.data.connect(cunit.I{1});
nplab3d.label.connect(gunit.aplabel);
gunit.approb.connect(prob.x);
% create priors
distinguish = DistVar(gunit.A);
distinguish.scale = -1e-2;
entropy = Entropy(cunit.O{1});
entropy.scale = -1;
% create task
task = CustomTask(taskid, taskdir, model, nplab3d, prob, {distinguish, entropy});
% run task
task.run(10, 10, 64, 64);
