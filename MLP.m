function mlp = MLP(inputSize, perceptronQuantityList, varargin)
assert(not(isempty(perceptronQuantityList)), ...
    'UMPrest:ArgumentError', 'Quantity list of percetrons is invalid');

conf     = Config(varargin);
hactType = conf.pop('HiddenLayerActType', 'ReLU');
oactType = conf.pop('OutputLayerActType', 'Logistic');

units    = cell(1, numel(perceptronQuantityList));
sizeinfo = [inputSize, perceptronQuantityList];
% create units
for i = 1 : numel(units) - 1
    units{i} = Perceptron( ...
        sizeinfo(i), sizeinfo(i + 1), 'actType', hactType);
end
units{end} = Perceptron(sizeinfo(end - 1), sizeinfo(end), 'actType', oactType);
% connect units
arrayfun(@(i) units{i}.aheadof(units{i+1}), 1 : numel(units) - 1);
% build model
mlp = Model(units);
