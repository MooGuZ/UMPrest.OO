classdef MLP < SequentialModel
    methods
        function obj = MLP(inputSize, perceptronQuantityList, varargin)
            assert(not(isempty(perceptronQuantityList)), ...
                'UMPrest:ArgumentError', 'Quantity list of percetrons is invalid');
            
            conf     = Config.parse(varargin);
            hactType = Config.popItem(conf, 'HiddenLayerActType', 'ReLU');
            oactType = Config.popItem(conf, 'OutputLayerActType', 'Logistic');
            
            sizeList = [inputSize, perceptronQuantityList];
            for i = 2 : numel(sizeList)
                obj.appendUnit(Perceptron(sizeList(i-1), sizeList(i)));
            end
            
            obj.unitList{end}.actType = oactType;
            for i = numel(obj.unitList) - 1 : -1 : 1
                obj.unitList{i}.actType = hactType;
            end
            
            Config.apply(obj, conf);
        end
    end
    
    methods (Static)
        function debug()
            inputSize = 400;
            psizeList = [512, 1024, 376, 128, 10];
            hactType  = 'ReLU';
            oactType  = 'Sigmoid';
            
            % main work flow
            model = MLP(inputSize, psizeList, ...
                'HiddenLayerActType', hactType, ...
                'OutputLayerActType', oactType, ...
                'tasktype', 'classify');
            % x = randn(inputSize, 1);
            % y = model.transform(x);
            % model.errprop(y);
            % model.update();
            datasource = load(UMPrest.path('data', 'tinytest'));
            ds = VideoDataset(MemoryDataBlock( ...
                MathLib.pack2cell(datasource.X'), ...
                StatisticCollector(), 'label', ...
                MathLib.pack2cell(MathLib.ind2tf(datasource.y, 1, 10))));
            model.train(ds, Likelihood('logistic'));
        end
    end
end
