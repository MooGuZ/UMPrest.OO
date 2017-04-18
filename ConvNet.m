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
        function [refer, aprox] = debug()
            verbose  = false;
            sizein   = [32, 32];
            nfilter  = [3, 5, 3];
            fltsize  = [3, 3];
            poolsize = [];
            nchannel = 3;
            refer = ConvNet.randinit(nchannel, nfilter, ...
                'filterSize', fltsize, 'poolsize', poolsize);
            aprox = ConvNet.randinit(nchannel, nfilter, ...
                'filterSize', fltsize, 'poolsize', poolsize);
            likelihood = Likelihood('mse');
            % create validate set
            % data = randn(sizein, 1e2);
            % validset = DataPackage(data, 'label', bsxfun(@plus, ltrans * data, bias));
            validsetIn  = DataPackage(randn([sizein, nchannel, 1e2]), 3, false);
            validsetOut = refer.forward(validsetIn);
            % get optimizer
            opt = HyperParam.getOptimizer();
            % setup optimizer
            opt.gradmode('basic');
            opt.stepmode('adapt', 'estimatedChange', 1e-2);            
            opt.enableRcdmode(3);
            % start to learn the linear transformation
            objval = likelihood.evaluate(aprox.forward(validsetIn).data, validsetOut.data);
            fprintf('Initial objective value : %.2f\n', objval);
            opt.record(objval, verbose);
            for i = 1 : UMPrest.parameter.get('iteration')
                data = randn([sizein, nchannel, 8]);
                ipkg = DataPackage(data, 3, false);
                opkg = refer.forward(ipkg);
                aprox.backward(likelihood.delta(aprox.forward(ipkg), opkg));
                aprox.update();
                objval = likelihood.evaluate(aprox.forward(validsetIn).data, validsetOut.data);
                fprintf('Objective Value after [%04d] turns: %.2e\n', i, objval);
                if mod(i, 10) == 0
                    opt.record(objval, verbose);
                end
            end
            % show result
            distinfo(abs(refer.dumpraw() - aprox.dumpraw()), 'HPARAMS', false);
        end
    end
end
