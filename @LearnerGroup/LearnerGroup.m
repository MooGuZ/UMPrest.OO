% LearnerGroup < DPModule & LearningModule & GPUModule
%   LearnerGroup suits for the learning modules that share the
%   same training data. One typical situation is that multiple
%   models representing different aspects of data.
%
% see also, DPModule, LearningModule, GPUModule
%
% MooGu Z. <hzhu@case.edu>
% Nov 20, 2015
%
% [Change Log]
% Nov 20, 2015 - initial commit
classdef LearnerGroup < DPModule & LearningModule & GPUModule
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function sample = proc(obj, sample)
            sampleArray = cell(1, numel(obj.group));
            for i = 1 : numel(obj.group)
                sampleArray{i} = obj.group{i}.proc(sample);
            end
            sample = obj.composeOutSample(sampleArray);
        end

        function sample = invp(obj, sample)
            sampleArray = cell(1, numel(obj.group));
            for i = 1 : numel(obj.group)
                sampleArray{i} = obj.group{i}.invp(sample);
            end
            sample = obj.composeInSample(sampleArray);
        end

        function setup(obj, dataset)
            % each module in the group only setup once
            if isempty(obj.group) || obj.ready()
                return
            end
            % setup learner one by one
            for i = 1 : numel(obj.group)
                if ~obj.group{i}.ready()
                    obj.group{i}.setup(dataset);
                end
            end
        end

        function tof = ready(obj)
            tof = true;
            for i = 1 : numel(obj.group)
                if not(obj.group{i}.ready())
                    tof = false;
                    return
                end
            end
        end

        % n = dimin(obj)
        % n = dimout(obj)
    end
    % ================= LEARNINGMODULE IMPLEMENTATION =================
    methods
        function learn(obj, sample)
            for i = 1 : numel(obj.group)
                obj.group{i}.learn(sample);
            end
        end

        function train(obj, dataset)
            % ensure necessary paramter have been setup
            if ~obj.ready(), obj.setup(dataset); end
            % train model by given dataset
            switch lower(obj.trainingMethod)
                case {'minibatch', 'stochastic'}
                    obj.miniBatch(dataset);
                otherwise
                    error('unrecognized training method : %s', obj.trainingMethod);
            end
        end

        info(obj)

        status(obj)
    end
    % ================= GPUMODULE IMPLEMENTATION =================
    methods
        function obj = activateGPU(obj)
            for i = 1 : numel(obj.group)
                if isa(obj.group{i}, 'GPUModule')
                    obj.stack{i}.activateGPU();
                end
            end
        end
        function obj = deactivateGPU(obj)
            for i = 1 : numel(obj.group)
                if isa(obj.group{i}, 'GPUModule')
                    obj.stack{i}.deactivateGPU();
                end
            end
        end
        function copy = clone(obj)
            copy = feval(class(obj));
            for i = 1 : numel(obj.group)
                if isa(obj.group{i}, 'GPUModule')
                    copy.push(obj.group{i}.clone());
                else
                    copy.push(obj.group{i});
                end
            end
        end
    end
    % ================= OTHER API =================
    methods
        function n = numel(obj)
            n = numel(obj.group);
        end
    end

    % ================= INTERFACE FOR SUBCLASS =================
    methods (Abstract)
        % COMPOSEINSAMPLE compose input sample from an array of samples
        sample = composeInSample(obj, sampleArray)
        % COMPOSEOUTSAMPLE compose output sample from an array of samples
        sample = composeOutSample(obj, sampleArray)
    end
    properties (Abstract)
        group
    end

    % ================= SUPPORT FUNCTION =================
    methods (Access = protected)
        function miniBatch(obj, dataset)
            for i = 1 : obj.traversePerTrain
                while not(dataset.istraversed())
                    % fetch data sample from dataset
                    sample = dataset.next(obj.samplePerBatch);
                    % involve model by learn sample
                    obj.learn(sample);
                    % count iteration
                    obj.count = obj.count + obj.samplePerBatch;
                    % show information and save current status
                    if obj.autosave(obj.count), obj.info(); end
                end
            end
            obj.autosave(true);
            obj.info();
        end
    end
end
