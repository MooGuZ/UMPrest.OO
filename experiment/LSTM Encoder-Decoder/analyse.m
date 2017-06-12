%% load trained-model
load records/UNCOND2048-ITER100000-DUMP.mat
%% setup experiments
nframes  = 20;
ncdfrms  = 10;
%% build model
encoder = Evolvable.loaddump(encoderdump);
decoder = Evolvable.loaddump(decoderdump);
predict = Evolvable.loaddump(predictdump);
encoder.stateAheadof(decoder).stateAheadof(predict);
%% load Moving MNIST dataset
load data/mmnist.mat
dataset = mmnist;
frmsize = [64, 64];
%% load Moving Dots dataset
load data/mvdot.mat
dataset = mvdot;
frmsize = [64, 64];
%% setup dataset
dataset.canvasSize      = frmsize;
dataset.maxSpeed        = [3, 3];
dataset.nframes         = nframes;
dataset.objectPerSample = 2;
%% load NPLab3D dataset
load data/nplab3d.mat
dataset = nplab3d;
frmsize = [32, 32];
%% setup nplab3d
dataset.enableSliceMode(nframes);
%% Extend Memeory Length Limit
decoder.recrtmode(nframes);
predict.recrtmode(nframes);
%% create tools
fslicer = FrameSlicer(ncdfrms, 'front', 0);
bslicer = FrameSlicer(nframes - ncdfrms, 'back', 0);
sslicer = FrameSlicer(nframes - ncdfrms, 'front', 0);
reverse = FrameReorder('reverse');
logact  = Activation('Logistic');
tanhact = Activation('tanh');
addon   = FrameInsert(1, 'front', 0);
%% add listeners
predictListeners = { ...
    'LastCellState',   Listener(predict.S{1}.O{1}); ...
    'LastHiddenState', Listener(predict.S{2}.O{1}); ...
    'GatedCellState',  Listener(predict.stateKeep.O{1}); ...
    'CellStateAddon',  Listener(predict.updateAct.O{1}); ...
    'GatedStateAddon', Listener(predict.stateAddon.O{1}); ...
    'NewCellState',    Listener(predict.stateNew.O{1}); ...
    'NewHiddenState',  Listener(predict.output.O{1});};
decoderListeners = { ...
    'LastCellState',   Listener(decoder.S{1}.O{1}); ...
    'LastHiddenState', Listener(decoder.S{2}.O{1}); ...
    'GatedCellState',  Listener(decoder.stateKeep.O{1}); ...
    'CellStateAddon',  Listener(decoder.updateAct.O{1}); ...
    'GatedStateAddon', Listener(decoder.stateAddon.O{1}); ...
    'NewCellState',    Listener(decoder.stateNew.O{1}); ...
    'NewHiddenState',  Listener(decoder.output.O{1});};    
%% sample counter
t = 0;
%% Generate Sample
sample = dataset.next();
t = t + 1;
%% setup decoder & predict
decoder.enableSelfeed(9);
predict.enableSelfeed(9);
%% Conditional Composite Model with Predicted Frames as Input
condString   = 'SemiConditional';
encoderInput = fslicer.forward(sample);
predictRefer = bslicer.forward(sample);
decoderInput = DataPackage(zeros(decoder.smpsize('in'), 1), 1, true);
predictInput = DataPackage(zeros(predict.smpsize('in'), 1), 1, true);
encoder.DI{1}.push(encoderInput);
encoder.forward();
decoder.DI{1}.push(decoderInput);
predict.DI{1}.push(predictInput);
decoderOutput = reverse.forward(logact.forward(decoder.forward()));
predictOutput = logact.forward(predict.forward());
%% diable selfeed mode
decoder.disableSelfeed();
predict.disableSelfeed();
%% Conditional Composite Model with True Frames as Input
condString   = 'Conditional';
encoderInput = fslicer.forward(sample);
predictRefer = bslicer.forward(sample);
decoderInput = sslicer.forward(addon.forward(reverse.forward(encoderInput)));
predictInput = sslicer.forward(addon.forward(predictRefer));
encoder.DI{1}.push(encoderInput);
encoder.forward();
decoder.DI{1}.push(decoderInput);
predict.DI{1}.push(predictInput);
decoderOutput = reverse.forward(logact.forward(decoder.forward()));
predictOutput = logact.forward(predict.forward());
%% Unconditional Composite Model
condString   = 'Unconditional';
encoderInput = fslicer.forward(sample);
predictRefer = bslicer.forward(sample);
decoderInput = DataPackage(zeros(decoder.smpsize('in'), nframes - ncdfrms), 1, true);
predictInput = DataPackage(zeros(predict.smpsize('in'), nframes - ncdfrms), 1, true);
encoder.DI{1}.push(encoderInput);
encoder.forward();
decoder.DI{1}.push(decoderInput);
predict.DI{1}.push(predictInput);
decoderOutput = reverse.forward(logact.forward(decoder.forward()));
predictOutput = logact.forward(predict.forward());
%% define save file name pattern
smpnmpt  = @(type, index) sprintf('fig/Sample-%02d-%s.gif', index, type);
basenmpt = @(type, cond)  sprintf('fig/Base-%s-%s.png', cond, type);
%% save animations
anim2gif(encoderInput.vectorize().data, smpnmpt('input', t), 'framerate', 12);
anim2gif(decoderOutput.data, smpnmpt('decoded', t), 'framerate', 12);
anim2gif(predictOutput.data, smpnmpt('predict', t), 'framerate', 12);
anim2gif(predictRefer.vectorize().data,  smpnmpt('future', t), 'framerate', 12);
%% draw bases of decoder and predict
decoderBase = decoder.outputTransform.weight;
predictBase = predict.outputTransform.weight;
[~, index]  = sort(sqrt(sum(decoderBase.^2)), 'descend');
decoderPick = reshape(decoderBase(:, index(1 : 200)), 64, 64, 200);
[~, index]  = sort(sqrt(sum(predictBase.^2)), 'descend');
predictPick = reshape(predictBase(:, index(1 : 200)), 64, 64, 200);
imwrite((MathLib.bound(imstackdraw(decoderPick, 'arrange', [10, 20]), ...
    [-1, 1]) + 1) / 2, basenmpt('Decoder-OutputTransform', condString), 'png');
imwrite((MathLib.bound(imstackdraw(predictPick, 'arrange', [10, 20]), ...
    [-1, 1]) + 1) / 2, basenmpt('Predict-OutputTransform', condString), 'png');
%% collect dynamic data
predictDynamic = cell(size(predictListeners, 1), 2);
for j = 1 : size(predictDynamic, 1)
    predictDynamic{j, 1} = predictListeners{j, 1};
    predictDynamic{j, 2} = predictListeners{j, 2}.collect();
end
decoderDynamic = cell(size(decoderListeners, 1), 2);
for j = 1 : size(decoderDynamic, 1)
    decoderDynamic{j, 1} = decoderListeners{j, 1};
    decoderDynamic{j, 2} = decoderListeners{j, 2}.collect();
end
%% draw inner state dynamics
for j = 1 : size(predictDynamic, 1)
    name = predictDynamic{j, 1};
    data = predictDynamic{j, 2};
    if not(strcmpi(name, 'NewHiddenState'))
        anim = tanhact.forward(data);
    end
    anim = logact.forward(predict.outputTransform.forward(anim));
    anim2gif(anim.data, smpnmpt(['Dynamic-Predict-', name], t), 'framerate', 12);
end
for j = 1 : size(decoderDynamic, 1)
    name = decoderDynamic{j, 1};
    data = decoderDynamic{j, 2};
    if not(strcmpi(name, 'NewHiddenState'))
        anim = tanhact.forward(data);
    end
    anim = logact.forward(predict.outputTransform.forward(anim));
    anim2gif(anim.data, smpnmpt(['Dynamic-Decoder-', name], t), 'framerate', 12);
end
%% clear all listeners
for j = 1 : size(predictListeners, 1)
    predictListeners{j, 2}.clear();
end
for j = 1 : size(decoderListeners, 1)
    decoderListeners{j, 2}.clear();
end
%% setup hidden state analysis
data  = predictDynamic{7, 2}.data;
unit  = predict.outputTransform;
nstep = 10;
%% analyse specific frame structure
nfrms = size(data, 2);
% initialization
order  = cell(1, nfrms);
evolve = cell(1, nfrms);
index  = cell(1, nfrms);
for i = 1 : size(data, 2)
    % sort element by energy
    [energy, order{i}] = sort(abs(data(:, i)), 'descend');
    percent = cumsum(energy) / sum(energy);
    % initialize data container
    index{i}  = zeros(1, nstep);
    evolve{i} = zeros(unit.smpsize('out'), nstep);
    for j = 1 : nstep
        p = 1 - (j - 1) / nstep;
        index{i}(j) = find(percent >= p, 1, 'first');
        simdata = data(:, i);
        simdata(order{i}(index{i}(j) + 1 : end)) = 0;
        frame = logact.forward(unit.forward(DataPackage(simdata, 1, true)));
        evolve{i}(:, j) = frame.data;
    end
end
% END
