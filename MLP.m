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
        function [refer, aprox] = debug()
            verbose    = true;
            validsize  = 1e3;
            batchsize  = 8;
            rcdintval  = 10;
            niteration = 1e3;
            % model parameters
            sizein   = 4;
            pqlist   = [4, 16, 4];
            hactType = 'ReLU';
            oactType = 'sigmoid';
            % create models
            refer = MLP.randinit(sizein, pqlist, ...
                'HiddenLayerActType', hactType, ...
                'OutputLayerActType', oactType);
            aprox = MLP.randinit(sizein, pqlist, ...
                'HiddenLayerActType', hactType, ...
                'OutputLayerActType', oactType);
            likelihood = Likelihood('mse');
            % create validate set
            validsetIn  = DataPackage(randn([sizein, validsize]), 1, false);
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
            for i = 1 : niteration
                data = randn([sizein, batchsize]);
                ipkg = DataPackage(data, 1, false);
                opkg = refer.forward(ipkg);
                aprox.backward(likelihood.delta(aprox.forward(ipkg), opkg));
                aprox.update();
                objval = likelihood.evaluate(aprox.forward(validsetIn).data, validsetOut.data);
                fprintf('Objective Value after [%04d] turns: %.2e\n', i, objval);
                if mod(i, rcdintval) == 0
                    opt.record(objval, verbose);
                end
            end
            % show result
            distinfo(abs(refer.dumpraw() - aprox.dumpraw()), 'HPARAMS', false);
        end
    end
end
