% DPLCoder is short for "Dual-Peephole LSTM Coder", which define a
% recurrent neural network based on a symetric design. This idea comes form
% a thought that combine complex bases with LSTM coder. It aims at do
% better prediction on our NPLab3D and Transform2D dataset.
classdef DPLCoder < WorkSpace
    % Methods for Object Construction and Save
    methods
        function obj = DPLCoder(encoder, predict, reTransform, imTransform, coTransform)
            % Get Size information
            obj.dataSize  = reTransform.smpsize('in');
            obj.stateSize = reTransform.smpsize('out');
            % Connect Core Units to build up core part of the model
            obj.RE = reTransform;
            obj.IM = imTransform;
            obj.crdTransform = Cart2Polar().appendto(obj.RE, obj.IM).aheadof( ...
                encoder.DI{1}, encoder.DI{2});
            obj.ENC = encoder.stateAheadof(predict);
            obj.PRD = predict;
            obj.ampact = SimpleActivation('ReLU').appendto(obj.PRD.DO{1});
            obj.angact = SimpleActivation('tanh').appendto(obj.PRD.DO{2});
            obj.angscaler = Scaler(pi).appendto(obj.angact);
            obj.CO = coTransform.appendto(obj.ampact, obj.angscaler);
            % Create model as a collection of core units
            obj.core = Model(obj.RE, obj.IM, obj.crdTransform, obj.ENC, ...
                obj.PRD, obj.ampact, obj.angact, obj.angscaler, obj.CO);
            % Create auxiliary generators
            obj.zerogen = DataGenerator('zero', obj.stateSize);
            obj.zerogen.data.connect(obj.PRD.DI{1});
            obj.zerogen.data.connect(obj.PRD.DI{2});
            obj.errgen = DataGenerator('zero', obj.stateSize, '-errmode');
            obj.errgen.data.connect(obj.ENC.DO{1});
            obj.errgen.data.connect(obj.ENC.DO{2});
        end

        function d = dump(obj)
            d = {'DPLCoder', obj.ENC.dump(), obj.PRD.dump(), ...
                obj.RE.dump(), obj.IM.dump(), obj.CO.dump()};
        end
    end
    methods (Static)
        function obj = randinit(stateSize, dataSize)
            % The construction of 2nd DPHLSTM is specified to fit the
            % structure of experiments which have done before. In fact, the
            % output transformation is not necessary here.
            obj = DPLCoder( ...
                DPHLSTM.randinit(stateSize, [], []), ...
                DPHLSTM.randinit(stateSize, [], stateSize), ...
                LinearTransform.randinit(dataSize, stateSize), ...
                LinearTransform.randinit(dataSize, stateSize), ...
                PolarCLT.randinit(stateSize, dataSize));
        end

        function obj = loadFromLegacy(taskid, datasetid, niter)
            % Solve path information
            taskdir = exproot();
            savedir = fullfile(taskdir, 'records');
            datadir = fullfile(taskdir, 'data');
            namept  = [taskid, '-ITER%d-DUMP.mat'];
            % Load dumps from file
            d = load(fullfile(savedir, sprintf(namept, niter)));
            % Compose units
            encoder     = BuildingBlock.loaddump(d.encoderdump);
            predict     = BuildingBlock.loaddump(d.predictdump);
            reTransform = BuildingBlock.loaddump(d.retransformdump);
            imTransform = BuildingBlock.loaddump(d.imtransformdump);
            if isfield(d, 'cotransformdump')
                coTransform = BuildingBlock.loaddump(d.cotransformdump);
            else
                comodel = load(fullfile(datadir, ['comodel_', lower(datasetid), '.mat']));
                coTransform = PolarCLT(comodel.rweight, comodel.iweight, ...
                    zeros(size(comodel.rweight, 1), 1));
            end
            % Create DPLCoder
            obj = DPLCoder(encoder, predict, reTransform, imTransform, coTransform);
            obj.iteration = niter;
        end
    end

    % Methods for Management
    methods
        function obj = connectDataset(obj, dataset, statUnit)
            obj.dataset = dataset;
            % Get statistic information directly from dataset, if necessary
            if not(exist('statUnit', 'var'))
                statUnit = dataset.stat;
            end
            % Build Statistic Transform, if necessary
            if isa(statUnit, 'StatisticTransform')
                obj.whitenUnit = statUnit;
            else
                obj.whitenUnit = StatisticTransform(statUnit, 'mode', 'whiten');
            end
            % Compress data according to the dataSize
            obj.whitenUnit.compressOutput(obj.dataSize);
            % Get statistic information
            statInfo = obj.whitenUnit.getKernel(dataset.framesize);
            % Create connection parts
            obj.inputSlicer = FrameSlicer().appendto(dataset.data).aheadof(obj.whitenUnit);
            obj.whitenUnit.aheadof(obj.RE).aheadof(obj.IM).freeze();
            obj.outputSlicer = FrameSlicer().appendto(dataset.data);
            obj.outputShaper = Reshaper().appendto(obj.outputSlicer);
            obj.dewhitenUnit = LinearTransform( ...
                statInfo.decode, statInfo.offset(:)).appendto(obj.CO).freeze();
            % Create Models as collection of Units
            obj.prev = Model(obj.inputSlicer, obj.whitenUnit, obj.outputSlicer, obj.outputShaper);
            obj.post = Model(obj.dewhitenUnit);
        end
        
        function obj = frameConfig(obj, nframeEncoder, nframePredict)
            % Setup dataset
            obj.dataset.nframes = nframeEncoder + nframePredict;
            % Setup frame slicers
            obj.inputSlicer.setup(nframeEncoder, 'front', 0);
            obj.outputSlicer.setup(nframePredict, 'front', nframeEncoder);
            % Setup auxiliary data sources
            obj.zerogen.enableTmode(nframePredict);
            obj.errgen.enableTmode(nframeEncoder);
        end
    end

    % Methods of Operations
    methods
        function obj = train(obj, taskid, nepoch, nbatch, varargin)
            conf = Config(varargin);
            % Setup Default Values
            saveInterval  = conf.pop('saveInterval', inf);
            estch         = conf.pop('estimatedChange', 1e-3);
            gradmode      = conf.pop('gradmode', 'adam');
            batchsize     = conf.pop('batchsize', 32);
            validsize     = conf.pop('validsize', 128);
            nframeEncoder = conf.pop('nframeEncoder', 15);
            nframePredict = conf.pop('nframePredict', 15);
            lossfunc      = conf.pop('lossFunction', 'mse');
            % Enable update of COModel if specified
            if conf.exist('updateCOModel')
                obj.CO.unfreeze();
            else
                obj.CO.freeze();
            end
            % Apply frame configure to each unit
            obj.frameConfig(nframeEncoder, nframePredict);
            % Setup Objectives
            obj.evalUnit = Likelihood(lossfunc);
            obj.evalUnit.x.connect(obj.dewhitenUnit.O{1});
            obj.evalUnit.ref.connect(obj.outputShaper.O{1});
            % Create Task for Training
            task = CustomTask(taskid, exproot(), obj.core, {obj.dataset, obj.zerogen}, ...
                obj.evalUnit, {}, 'prevnet', obj.prev, 'postnet', obj.post, 'errgen', obj.errgen, ...
                'saveInterval', saveInterval);
            task.setWorkSpace(obj);
            % setup optmizator
            opt = HyperParam.getOptimizer();
            opt.gradmode(gradmode);
            opt.stepmode('adapt', 'estimatedChange', estch);
            opt.enableRcdmode(3);
            % run task
            task.run(nepoch, nbatch, batchsize, validsize);
        end
        
        function [sampleIn, sampleRef, sampleOut] = sample(obj, n, nframeEncode, nframePredict)
            % Apply frame configure to each unit
            obj.frameConfig(nframeEncode, nframePredict);
            % Generate data
            obj.dataset.next(n);
            obj.zerogen.next(n);
            % Model process the data
            obj.prev.forward();
            obj.core.forward();
            obj.post.forward();
            % Get samples
            sampleIn  = obj.inputSlicer.O{1}.packagercd;
            sampleRef = obj.outputSlicer.O{1}.packagercd;
            sampleOut = obj.dewhitenUnit.O{1}.packagercd.reshape(obj.dataset.framesize);
        end
    end
    
    properties
        stateSize, dataSize  % Size Information
        RE, IM, ENC, PRD, CO % Core Units
        zerogen, errgen      % Auxiliary Data Generators
        % Connecting Parts
        crdTransform, ampact, angact, angscaler
        inputSlicer, outputSlicer, outputShaper
        % Statistic Units
        whitenUnit, dewhitenUnit
        % Objective Units
        evalUnit
    end
end
