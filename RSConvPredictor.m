% Recurrent Steerable Convolutional Predictor
classdef RSConvPredictor < WorkSpace
    % Methods for Object Construction and Save
    methods
        function obj = RSConvPredictor(encoder, predictor)
            % Get Size information
            obj.dataSize  = encoder.nhidden;
            obj.stateSize = encoder.nstate;
            % Connect Core Units to build up core part of the model
            obj.ENC = encoder.stateAheadof(predictor);
            obj.PRD = predictor;
            % Create model as a collection of core units
            obj.core = Model(obj.ENC, obj.PRD);
            % Create auxiliary generators
            obj.zerogen = DataGenerator('zero', obj.dataSize);
            obj.zerogen.data.connect(obj.PRD.DI{1});
            obj.errgen = DataGenerator('zero', obj.dataSize, '-errmode');
            obj.errgen.data.connect(obj.ENC.DO{1});
        end

        function d = dump(obj)
            d = {'RSConvPredictor', obj.ENC.dump(), obj.PRD.dump()};
        end
    end
    methods (Static)
        function obj = randinit(frmsize, nlayerFrm, basesize, nbase, grid)
            if not(exist('grid', 'var'))
                grid = [1, 1];
            end
            
            obj = RSConvPredictor( ...
                RSConvEncoder.randinit(frmsize, nlayerFrm, basesize, nbase, grid), ...
                RSConvDecoder.randinit(frmsize, nlayerFrm, basesize, nbase, grid));
        end
    end

    % Methods for Management
    methods
        function obj = connectDataset(obj, dataset, statUnit)
            obj.dataset = dataset;
            % setup framesize to match encoder and predictor
            if isfield(dataset, 'framesize')
                dataset.framesize = obj.ENC.framesize;
            end
            % Get statistic information directly from dataset, if necessary
            if not(exist('statUnit', 'var'))
                statUnit = dataset.stat;
            end
            % Build Statistic Transform, if necessary
            if isa(statUnit, 'StatisticTransform')
                obj.whitenUnit = statUnit;
                obj.whitenUnit.mode = 'zerophase';
            else
                obj.whitenUnit = StatisticTransform(statUnit, 'mode', 'zerophase');
            end
            % Get statistic information
            statInfo = obj.whitenUnit.getKernel(obj.ENC.framesize);
            % Create connection parts
            obj.inputSlicer = FrameSlicer().appendto(dataset.data).aheadof(obj.whitenUnit);
            obj.whitenUnit.aheadof(obj.ENC.DI{1}).freeze();
            obj.outputSlicer = FrameSlicer().appendto(dataset.data);
            obj.outputShaper = Reshaper().appendto(obj.outputSlicer);
            obj.dewhitenUnit = LinearTransform( ...
                statInfo.decodeZero, statInfo.offset(:)).appendto(obj.PRD.DO{1}).freeze();
            % Create Models as collection of Units
            obj.prev = Model(obj.inputSlicer, obj.whitenUnit, obj.outputSlicer, obj.outputShaper);
            obj.post = Model(obj.dewhitenUnit);
        end
        
        function obj = frameConfig(obj, nframeEncoder, nframePredict)
            % Setup dataset
            if isfield(obj.dataset, 'nframes')
                obj.dataset.nframes = nframeEncoder + nframePredict;
            end
            % Setup frame slicers
            obj.inputSlicer.setup(nframeEncoder, 'front', 0);
            obj.outputSlicer.setup(nframePredict, 'front', nframeEncoder);
            % Setup auxiliary data sources
            obj.zerogen.enableTmode(nframePredict);
            obj.errgen.enableTmode(nframeEncoder);
            % setup memory length of encoder and predictor
            obj.ENC.recrtmode(nframeEncoder);
            obj.PRD.recrtmode(nframePredict);
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
        ENC, PRD             % Core Units
        zerogen, errgen      % Auxiliary Data Generators
        % Connecting Parts
        inputSlicer, outputSlicer, outputShaper
        % Statistic Units
        whitenUnit, dewhitenUnit
        % Objective Units
        evalUnit
    end
end
