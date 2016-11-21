function model = MLP(inputSize, perceptronQuantityList, varargin)
assert(not(isempty(perceptronQuantityList)), ...
    'UMPrest:ArgumentError', 'Quantity list of percetrons is invalid');

conf     = Config(varargin);
hactType = conf.pop('HiddenLayerActType', 'ReLU');
oactType = conf.pop('OutputLayerActType', 'Logistic');

perceptrons = cell(1, numel(perceptronQuantityList));
sizeinfo  = [inputSize, perceptronQuantityList];
% create perceptrons
for i = 1 : numel(perceptrons) - 1
    perceptrons{i} = Perceptron( ...
        sizeinfo(i), sizeinfo(i + 1), 'actType', hactType);
end
perceptrons{end} = Perceptron(sizeinfo(end - 1), sizeinfo(end), 'actType', oactType);
% connect perceptrons
for i = 1 : numel(perceptrons) - 1
    perceptrons{i}.connectTo(perceptrons{i+1});
end
% build model
model = Model();
model.add(perceptrons{:});
