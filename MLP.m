classdef MLP < Model
    methods
        function obj = MLP(varargin)
            units = varargin(1 : end - 2);
            hactType = varargin{end - 1};
            oactType = varargin{end};
            % generate activation units
            acts  = cell(1, numel(units));
            for i = 1 : numel(acts) - 1
                acts{i} = Activation(hactType);
                acts{i}.appendto(units{i}).aheadof(units{i+1});
            end
            acts{end} = Activation(oactType);
            acts{end}.appendto(units{end});
            units = [units; acts];
            obj@Model(units{:});
            % assign properties
            obj.hactType = hactType;
            obj.oactType = oactType;
        end
    end
    
    % ============= DUMP & LOAD =============
    methods
        function modeldump = dump(obj)
            modeldump = cellfun(@dump, obj.evolvable, 'UniformOutput', false);
            modeldump = [{'MLP'}, modeldump, {obj.hactType, obj.oactType}];
        end
    end
    
    methods (Static)
        function mlp = randinit(inputSize, perceptronQuantityList, varargin)
            assert(not(isempty(perceptronQuantityList)), ...
                'UMPrest:ArgumentError', 'Quantity list of percetrons is invalid');
            
            conf = Config(varargin);
            hactType = conf.pop('HiddenLayerActType', 'ReLU');
            oactType = conf.pop('OutputLayerActType', 'Logistic');
            
            units    = cell(1, numel(perceptronQuantityList));
            sizeinfo = [inputSize, perceptronQuantityList];
            % create units
            for i = 1 : numel(units)
                units{i} = LinearTransform.randinit( ...
                    sizeinfo(i), sizeinfo(i + 1));
            end
            % generate MLP
            mlp = MLP(units{:}, hactType, oactType);
        end
    end
    
    properties
        hactType, oactType
    end
    
    methods (Static)
        function debug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 3e2; end
            if not(exist('batchsize', 'var')), batchsize = 16;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            % model parameters
            nlayer   = ceil(log2(probScale));
            nunits   = probScale * ones(1, nlayer + 1);
            hactType = 'ReLU';
            oactType = 'tanh';
            % create reference model
            refer = MLP.randinit(nunits(1), nunits(2:end), ...
                'HiddenLayerActType', hactType, ...
                'OutputLayerActType', oactType);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            % create approximate model
            model = MLP.randinit(nunits(1), nunits(2:end), ...
                'HiddenLayerActType', hactType, ...
                'OutputLayerActType', oactType);
            % data generator
            dataset = DataGenerator('normal', nunits(1));
            % objective funtion
            objective = Likelihood('mse');
            % create simulation task
            task = SimulationTest(model, refer, dataset, objective);
            % run test
            task.run(niter, batchsize, validsize);
        end
    end
end
