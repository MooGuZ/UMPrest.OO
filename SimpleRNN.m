classdef SimpleRNN < RecurrentUnit
    methods
        function value = smpsize(obj, io)
            switch lower(io)
                case {'in', 'input'}
                    if isempty(obj.inputTransform)
                        value = obj.nhidunit;
                    else
                        value = obj.inputTransform.smpsize('in');
                    end
                    
                case {'out', 'output'}
                    if isempty(obj.outputTransform)
                        value = obj.nhidunit;
                    else
                        value = obj.outputTransform.smpsize('out');
                    end
                    
                otherwise
                    error('UNSUPPORTED');
            end
        end
        
        function unitdump = dump(obj)
            unitdump = {'SimpleRNN', obj.transform.dump()};
            % add input tranform
            if isempty(obj.inputTransform)
                unitdump = [unitdump, {[]}];
            else
                unitdump = [unitdump, {obj.inputTransform.dump()}];
            end
            % add output transform
            if isempty(obj.outputTransform)
                unitdump = [unitdump, {[]}];
            else
                unitdump = [unitdump, {obj.outputTransform.dump()}];
            end
        end
    end
    
    properties (SetAccess = protected)
        nhidunit, transform, activation, inputTransform, outputTransform
    end
    
    methods
        function obj = SimpleRNN(transform, inputTransform, outputTransform)
            activation = SimpleActivation('tanh').appendto(transform);
            % create model
            model = Model(transform, activation);
            % add input transform
            if not(isempty(inputTransform))
                inputTransform.aheadof(transform.I{2});
                model.add(inputTransform);
            end
            % add output transform
            if not(isempty(outputTransform))
                outputTransform.appendto(activation);
                model.add(outputTransform);
            end
            obj@RecurrentUnit(model, ...
                {activation.O{1}, transform.I{1}, transform.smpsize('out')});
            % get number of hidden units
            obj.nhidunit        = obj.S{1}.statesize;
            % assign units to class properties for quick access
            obj.transform       = transform;
            obj.activation      = activation;
            obj.inputTransform  = inputTransform;
            obj.outputTransform = outputTransform;
        end
    end
    
    methods (Static)
        function obj = randinit(nhidden, sizein, sizeout)
            % create input transform
            if exist('sizein', 'var') && not(isempty(sizein))
                inputTransform = LinearTransform.randinit(sizein, nhidden);
            else
                inputTransform = [];
            end
            % create output transform
            if exist('sizeout', 'var') && not(isempty(sizeout))
                outputTransform = LinearTransform.randinit(nhidden, sizeout);
            else
                outputTransform = [];
            end
            % create SimpleRNN
            obj = SimpleRNN( ....
                MultiLT.randinit(nhidden, nhidden, nhidden), ...
                inputTransform, outputTransform);
        end
        
        function debug()
            nhidden = 16;
            sizein  = 8;
            sizeout = 32;
            nframes = 7;
            % calculate data size
            if isempty(sizein)
                datasize = nhidden;
            else
                datasize = sizein;
            end
            % create model and its reference
            refer = SimpleRNN.randinit(nhidden, sizein, sizeout);
            model = SimpleRNN.randinit(nhidden, sizein, sizeout);
            % % set as last-frame mode
            % refer.setupOutputMode('last');
            % model.setupOutputMode('last');
            % create dataset
            dataset = DataGenerator('normal', datasize).enableTmode(nframes);
            % create objectives
            objective = Likelihood('mse');
            % initialize task
            task = SimulationTest(model, refer, dataset, objective);
            % setup optimizer
            opt = HyperParam.getOptimizer();
            opt.gradmode('basic');
            opt.stepmode('adapt', 'estimatedChange', 1e-2);
            opt.enableRcdmode(3);
            % run simulation test
            task.run(300, 16, 64);
        end
    end
end