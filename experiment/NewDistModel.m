taskid  = 'NEWDISTMODEL';
taskdir = fileparts(mfilename('fullpath'));
% model parameters
nfrmin  = 3;
nfrmout = 3;
psize   = [2, 2];
frmsize = [32, 32];
sizeout = prod([4, 4, nfrmout]);
ncat    = 5;
nbasis  = ceil(sizeout * 1.2);
% create units and model
cunit   = ConvNet.randinit(nfrmin, [2 * nfrmin, 4 * nfrmin, nfrmout], ...
    'poolsize', psize, 'OutputLayerActType', 'Sigmoid');
gunit   = GaussianMixtureUnit(ncat, nbasis, sizeout);
dshaper = Reshaper().appendto(cunit).aheadof(gunit.apdata);
model   = Model(cunit, dshaper, gunit);
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
% create task
task = CustomTask(taskid, taskdir, model, nplab3d, prob, {distinguish});
% run task
task.run(10, 100, 16, 64);
