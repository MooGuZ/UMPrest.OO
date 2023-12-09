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
            hactType = conf.pop('HiddenLayerActType', 'tanh');
            oactType = conf.pop('OutputLayerActType', 'Sigmoid');
            
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
        function [refer, model] = debug(nlayer, probScale, niter, batchsize, validsize)
            if not(exist('probScale', 'var')), probScale = 16;  end
            if not(exist('niter',     'var')), niter     = 1e3; end
            if not(exist('batchsize', 'var')), batchsize = 64;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            hactType = 'linear';
            oactType = 'linear';
            % create reference model
            refer = MLP.randinit(probScale, probScale * ones(1,nlayer), ...
                'HiddenLayerActType', hactType, ...
                'OutputLayerActType', oactType);
            cellfun(@(hp) hp.set(randn(size(hp))), refer.hparam);
            refer.update();
            % create approximate model
            model = MLP.randinit(probScale, probScale * ones(1,nlayer), ...
                'HiddenLayerActType', hactType, ...
                'OutputLayerActType', oactType);
            % data generator
            dataset = DataGenerator('normal', probScale);
            % objective funtion
            objective = Likelihood('mse');
            % create simulation task
            task = SimulationTest(model, refer, dataset, objective);
            % run test
            task.run(niter, batchsize, validsize);
        end
        
        function [refer, model] = simshape(type, hidunit, niter, batchsize, validsize)
            if not(exist('niter',     'var')), niter     = 1e3; end
            if not(exist('batchsize', 'var')), batchsize = 64;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            % create reference model
            refer = SimpleShape.randinit(type);
            % create MLP
            model = MLP.randinit(2, [hidunit, 2], ...
                'HiddenLayerActType', 'tanh', ...
                'OutputLayerActType', 'softmax');
            % data generator
            dataset = DataGenerator('normal', 2);
            % objective funtion
            objective = Likelihood('mse');
            % create simulation task
            task = SimulationTest(model, refer, dataset, objective);
            task.rawcompare = false;
            % run test
            task.run(niter, batchsize, validsize);
            % draw the result
            resolution = 512;
            [X, Y] = meshgrid(linspace(-3, 3, resolution), linspace(3, -3, resolution));
            I = DataPackage([X(:), Y(:)]', 1, false);
            O = refer.forward(I);
            P = model.forward(I);
            figure();
            set(gcf, 'Position', [680 690 580 290]);
            subplot(1,2,1);
            imshow(reshape(O.data(1, :), resolution * [1,1]));
            title('Ground Truth');
            subplot(1,2,2);
            imshow(reshape(P.data(1, :), resolution * [1,1]));
            title('Model Simulation');
        end

        function [refer, model] = simPhaseField(hidunit, niter, batchsize, validsize)
            if not(exist('niter',     'var')), niter     = 1e3; end
            if not(exist('batchsize', 'var')), batchsize = 64;  end
            if not(exist('validsize', 'var')), validsize = 128; end
            
            % create reference model
            % refer = PhaseField.randinit().getEquivalentLinearTransform();
            refer = PhaseField.randinit();
            % create MLP
            model = RUnit(MLP.randinit(2, [hidunit, 2], ...
                'HiddenLayerActType', 'ReLU', ...
                'OutputLayerActType', 'Linear'));
            % setup number of frames used in optimization
            refer.nframes = 5;
            model.nframes = 5;
            % data generator
            dataset = DataGenerator('normal', 2).enableTmode(1);
            % objective funtion
            objective = Likelihood('mse');
            % create simulation task
            task = SimulationTest(model, refer, dataset, objective);
            task.rawcompare = false;
            % run test
            task.run(niter, batchsize, validsize);
            % illustrate the results
            refer.nframes = 30;
            model.nframes = 30;
            txtrnd = iDCT2Function.randinit(32,32);
            maskpt = SimpleShape.randinit('circle');
            [X,Y] = meshgrid(linspace(-1,1,256), linspace(1,-1,256));
            pfinit = DataPackage([X(:), Y(:)]', 1, false).enableTaxis();
            pfref  = refer.forward(pfinit);
            pfmod  = model.forward(pfinit);
            output = txtrnd.forward(pfref).data .* maskpt.forward(pfref).data;
            animrf = permute(output, [3,2,1]);
            output = txtrnd.forward(pfmod).data .* maskpt.forward(pfmod).data;
            animmd = permute(output, [3,2,1]);
            animview({animrf, animmd});
        end
    end
end
