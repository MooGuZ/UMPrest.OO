% LSTMCoder is a reproduction of model in Srivastava's paper
classdef LSTMCoder < WorkSpace
    % Methods for Object Construction and Save
    %
    %   One thing needs to be noticed is that construction of a recurrent
    %   unit has freedom in whether or not create input/output transforms.
    %   Especially, the output/input transform is unnecessary for encoder
    %   and decoder/predict. This would affect the setting for auxiliary
    %   data generator here.
    methods
        function obj = LSTMCoder(encoder, decoder, predict)
            % Get Size information
            obj.stateSize = encoder.nhidunit;
            obj.dataSize  = encoder.smpsize('in');
            % Connect Core Units to build up core part of the model
            obj.ENC = encoder.stateAheadof(decoder).stateAheadof(predict);
            obj.DEC = decoder;
            obj.PRD = predict;            
            % Create model as a collection of core units
            obj.core = Model(obj.ENC, obj.DEC, obj.PRD);
            % Create auxiliary generators
            obj.zerodec = DataGenerator('zero', obj.dataSize);
            obj.zerodec.data.connect(obj.DEC.DI{1});
            obj.zeroprd = DataGenerator('zero', obj.dataSize);
            obj.zeroprd.data.connect(obj.PRD.DI{1});
            obj.errgen = DataGenerator('zero', obj.stateSize, '-errmode');
            obj.errgen.data.connect(obj.ENC.DO{1});
        end

        function d = dump(obj)
            d = {'LSTMCoder', obj.ENC.dump(), obj.DEC.dump(), obj.PRD.dump()};
        end
    end
    methods (Static)
        function obj = randinit(stateSize, dataSize)
            % The construction methods here is a legacy.
            obj = LSTMCoder( ...
                PHLSTM.randinit(stateSize, dataSize), ...
                PHLSTM.randinit(stateSize, dataSize, dataSize), ...
                PHLSTM.randinit(stateSize, dataSize, dataSize));
        end

        function obj = loadFromLegacy(taskid, niter)
            % Solve path information
            taskdir = exproot();
            savedir = fullfile(taskdir, 'records');
            namept  = [taskid, '-ITER%d-DUMP.mat'];
            % Load dumps from file
            d = load(fullfile(savedir, sprintf(namept, niter)));
            % Compose units
            encoder = BuildingBlock.loaddump(d.encoderdump);
            decoder = BuildingBlock.loaddump(d.decoderdump);
            predict = BuildingBlock.loaddump(d.predictdump);
            % Create LSTMCoder
            obj = LSTMCoder(encoder, decoder, predict);
            obj.iteration = niter;
        end
    end

    % Methods for Management
    methods
        function obj = connectDataset(obj, dataset)
            obj.dataset = dataset;
            % Create connection parts
            obj.encoderInput    = FrameSlicer().appendto(dataset.data).aheadof(obj.ENC.DI{1});
            obj.decoderRefer    = FrameReorder('reverse').appendto(obj.encoderInput);
            obj.decoderReferFix = Reshaper().appendto(obj.decoderRefer);
            obj.predictRefer    = FrameSlicer().appendto(dataset.data);
            obj.predictReferFix = Reshaper().appendto(obj.predictRefer);
            obj.decoderAct      = SimpleActivation('logistic').appendto(obj.DEC.DO{1});
            obj.predictAct      = SimpleActivation('logistic').appendto(obj.PRD.DO{1});
            % Create Models as collection of Units
            obj.prev = Model(obj.encoderInput, obj.decoderRefer, obj.decoderReferFix, ...
                obj.predictRefer, obj.predictReferFix);
            obj.post = Model(obj.decoderAct, obj.predictAct);
        end
        
        function obj = frameConfig(obj, nframeEncoder, nframePredict)
            % Setup dataset
            obj.dataset.nframes = nframeEncoder + nframePredict;
            % Setup frame slicers
            obj.encoderInput.setup(nframeEncoder, 'front', 0);
            obj.predictRefer.setup(nframePredict, 'front', nframeEncoder);
            % Setup auxiliary data sources
            obj.zerodec.enableTmode(nframeEncoder);
            obj.zeroprd.enableTmode(nframePredict);
            obj.errgen.enableTmode(nframeEncoder);
            % Setup cheating units if enabled
            if obj.cheatMode
                obj.decoderCheatFix.setup(nframeEncoder, 'front', 0);
                obj.predictCheatFix.setup(nframePredict, 'front', 0);
            end
        end
        
        % CHEATING MODE provide last frames to decoder and predict, which
        % is actually cheating in prediction.
        function obj = startCheating(obj)
            if not(obj.cheatMode)
                % initialize cheating connections if necessary
                if isempty(obj.decoderCheat)
                    obj.decoderCheat = FrameInsert(1, 'front', 0).appendto(obj.decoderReferFix);
                    obj.decoderCheatFix = FrameSlicer().appendto(obj.decoderCheat);
                    obj.predictCheat = FrameInsert(1, 'front', 0).appendto(obj.predictReferFix);
                    obj.predictCheatFix = FrameSlicer().appendto(obj.predictCheat);
                    obj.prev.add(obj.decoderCheat, obj.decoderCheatFix, ...
                        obj.predictCheat, obj.predictCheatFix);
                end
                % Switch connections to decoder/predict
                obj.zerodec.data.disconnect(obj.DEC.DI{1});
                obj.decoderCheatFix.O{1}.connect(obj.DEC.DI{1});
                obj.zeroprd.data.disconnect(obj.PRD.DI{1});
                obj.predictCheatFix.O{1}.connect(obj.PRD.DI{1});
                % switch indicator
                obj.cheatMode = true;
            end
        end
        function obj = stopCheating(obj)
            if obj.cheatMode
                % Switch connections to decoder/predict
                obj.decoderCheatFix.O{1}.disconnect(obj.DEC.DI{1});
                obj.zerodec.data.connect(obj.DEC.DI{1});
                obj.predictCheatFix.O{1}.disconnect(obj.PRD.DI{1});
                obj.zeroprd.data.connect(obj.PRD.DI{1});
                % Switch the mode indicator
                obj.cheatMode = false;
            end
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
            lossfunc      = conf.pop('lossFunction', 'cross-entropy');
            % Apply frame configure to each unit
            obj.frameConfig(nframeEncoder, nframePredict);
            % Setup Objectives
            obj.decObjective = Likelihood(lossfunc);
            obj.decObjective.x.connect(obj.decoderAct.O{1});
            obj.decObjective.ref.connect(obj.decoderReferFix.O{1});
            obj.prdObjective = Likelihood(lossfunc);
            obj.prdObjective.x.connect(obj.predictAct.O{1});
            obj.prdObjective.ref.connect(obj.predictReferFix.O{1});
            % Create Task for Training
            task = CustomTask(taskid, exproot(), obj.core, {obj.dataset, obj.zerodec, obj.zeroprd}, ...
                {obj.decObjective, obj.prdObjective}, {}, 'prevnet', obj.prev, 'postnet', obj.post, ...
                'errgen', obj.errgen, 'saveInterval', saveInterval);
            task.setWorkSpace(obj);
            % setup optmizator
            opt = HyperParam.getOptimizer();
            opt.gradmode(gradmode);
            opt.stepmode('adapt', 'estimatedChange', estch);
            opt.enableRcdmode(3);
            % run task
            task.run(nepoch, nbatch, batchsize, validsize);
        end
        
        function [smpIn, smpNxt, smpDec, smpPrd] = sample(obj, n, nframeEncode, nframePredict)
            % Apply frame configure to each unit
            obj.frameConfig(nframeEncode, nframePredict);
            % Generate data
            obj.dataset.next(n);
            obj.zerodec.next(n);
            obj.zeroprd.next(n);
            % Model process the data
            obj.prev.forward();
            obj.core.forward();
            obj.post.forward();
            % Get samples
            smpIn  = obj.encoderInput.O{1}.packagercd;
            smpNxt = obj.predictRefer.O{1}.packagercd;
            smpDec = obj.decoderAct.O{1}.packagercd.reshape(obj.dataset.framesize);
            smpPrd = obj.predictAct.O{1}.packagercd.reshape(obj.dataset.framesize);
        end
        
        function obj = startRecording(obj)
            if not(obj.recordMode)
                obj.ENC.startRecording();
                obj.DEC.startRecording();
                obj.PRD.startRecording();
                obj.recordMode = true;
            end
        end
        
        function obj = stopRecording(obj)
            if obj.recordMode
                obj.ENC.stopRecording();
                obj.DEC.stopRecording();
                obj.PRD.stopRecording();
                obj.recordMode = false;
            end
        end
        
        function records = getRecords(obj)
            if obj.recordMode
                records = struct( ...
                    'encoder', obj.ENC.getRecords(), ...
                    'decoder', obj.DEC.getRecords(), ...
                    'predict', obj.PRD.getRecords());
            else
                warning('Model is not recording, use startRecording() at first.');
            end
        end
    end
    
    properties
        stateSize, dataSize  % Size Information
        ENC, DEC, PRD        % Core Units
        zerodec, zeroprd, errgen % Auxiliary Data Generators
        % Connecting Parts
        encoderInput, decoderRefer, decoderReferFix
        predictRefer, predictReferFix, decoderAct, predictAct
        % Objective Units
        decObjective, prdObjective
        % cheatMode related
        decoderCheat, decoderCheatFix, predictCheat, predictCheatFix
        cheatMode = false
        % recordMode
        recordMode = false
    end
end
