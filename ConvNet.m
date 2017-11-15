classdef ConvNet < Model
    methods
        function obj = ConvNet(varargin)
            units = varargin(1 : end - 3);
            poolsize = varargin{end - 2};
            hactType = varargin{end - 1};
            oactType = varargin{end};
            % generate pooling units
            pools = cell(1, numel(units));
            if not(isempty(poolsize))
                if not(iscell(poolsize))
                    poolsize = repmat({poolsize}, 1, numel(units));
                end
                for i = 1 : numel(pools)
                    if not(isempty(poolsize{i}))
                        pools{i} = MaxPool(poolsize{i});
                    end
                end
            end
            % generate activation units
            acts = cell(1, numel(units));
            for i = 1 : numel(acts) - 1
                acts{i} = Activation(hactType);
            end
            acts{end} = Activation(oactType);
            % connect units
            for i = 1 : numel(units) - 1
                if isempty(pools{i})
                    acts{i}.appendto(units{i}).aheadof(units{i+1});
                else
                    pools{i}.appendto(units{i}).aheadof(acts{i});
                    acts{i}.aheadof(units{i+1});
                end
            end
            % connect the last unit
            if isempty(pools{end})
                acts{end}.appendto(units{end});
            else
                pools{end}.appendto(units{end}).aheadof(acts{end});
            end
            % build model
            units = [units; pools; acts];
            obj@Model(units{:});
            obj.hactType = hactType;
            obj.oactType = oactType;
            if isempty(poolsize)
                obj.poolsize = [];
            else
                obj.poolsize = poolsize{1}; % BUG: this is a quick fix
            end
        end
    end
    
    % ============= DUMP & LOAD =============
    methods
        function modeldump = dump(obj)
            modeldump = cellfun(@dump, obj.evolvable, 'UniformOutput', false);
            modeldump = [{'ConvNet'}, modeldump, {obj.poolsize, obj.hactType, obj.oactType}];
        end
    end
    
    methods (Static)
        function convnet = randinit(nchannel, nfilter, varargin)
            conf = Config(varargin);
            fltsize  = conf.pop('filterSize', [5, 5]);
            poolsize = conf.pop('poolsize', []);
            hactType = conf.pop('HiddenLayerActType', 'ReLU');
            oactType = conf.pop('OutputLayerActType', 'Sigmoid');
            
            units = cell(1, numel(nfilter));
            
            if iscell(fltsize)
                assert(numel(fltsize) == numel(units));
            else
                fltsize = repmat({fltsize}, 1, numel(units));
            end
            
            nfilter = [nchannel, nfilter];
            for i = 1 : numel(units)
                units{i} = ConvTransform.randinit(fltsize{i}, nfilter(i), nfilter(i + 1));
            end
            
            convnet = ConvNet(units{:}, poolsize, hactType, oactType);
        end
    end
    
    properties
        hactType, oactType, poolsize
    end
    
    methods (Static)
        function debug(probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;     end
            if not(exist('niter',     'var')), niter     = 3e2;    end
            if not(exist('batchsize', 'var')), batchsize = 16;     end
            if not(exist('validsize', 'var')), validsize = 128;    end
            
            % setup parameters
            nlayer   = ceil(log2(probScale));
            sizein   = probScale * [1,1];
            nchannel = nlayer;
            fltsize  = ceil(sqrt(sizein));
            nfilter  = [nchannel, nlayer * ones(1, nlayer)];
            hactType = 'ReLU';
            oactType = 'tanh';
            % reference model
            refer = ConvNet.randinit(nchannel, nfilter(2 : end), 'filterSize', fltsize, ...
                'HiddenLayerActType', hactType, 'OutputLayerActType', oactType);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            % approximate model
            model = ConvNet.randinit(nchannel, nfilter(2 : end), 'filterSize', fltsize, ...
                'HiddenLayerActType', hactType, 'OutputLayerActType', oactType);
            % create dataset
            dataset = DataGenerator('normal', [sizein, nchannel]);
            % create objectives
            likelihood = Likelihood('mse');
            % create simulation task
            task = SimulationTest(model, refer, dataset, likelihood);
            % run simulation
            task.run(niter, batchsize, validsize);
        end
    end
end
