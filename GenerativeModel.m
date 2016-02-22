% GenerativeModel < DPModule & LearningModule & GPUModule & UtilityLib
%   GenerativeModel represents generative models that simulate generating process
%   of specific data, such as video. This class provide fundamental interfaces of
%   genrative model to developers to fillin in subclasses, while provide functions
%   that implemented data processing and learning protocols to users to operate.
%
% [INTERFACE]
%   initBase(obj, sample)
%   respond = initRespond(obj, sample)
%   respond = infer(obj, sample, start)
%   sample = generate(obj, respond)
%   adapt(obj, sample, respond)
%   update(obj, delta)
%   objval = evaluate(obj, sample, respond)
%   mgrad = modelGradient(obj, sample, respond)
%   rgrad = respondGradient(obj, sample, respond)
%
% [INHERIENT INTERFACE]
%   copy = clone(obj) % GPUModule
%
% [CONFIGURABLE PROPERTY]
%   updatePerSample  : 1
%   traversePerTrain : 3
%   samplePerBatch   : 1
%   trainingMethod   : 'minibatch'
%
% see also, DPModule, LearningModule, GPUModule, UtilityLib
%
% MooGu Z. <hzhu@case.edu>
% Sept 30, 2015
%
% [Change Log]
% Sep 30, 2015 - initial commit
% Dec 08, 2015 - update definition of 'setup'
% Dec 09, 2015 - fixed infinite loop in 'miniBatch'
classdef GenerativeModel < DPModule & LearningModule & GPUModule & AutoSave
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function respond = proc(obj, sample)
            respond = obj.infer(obj.preproc.proc(sample));
        end

        function sample = invp(obj, respond)
            sample = obj.preproc.invp(obj.generate(respond));
        end

        function setup(obj, dataset)
            % setup proprocessing stack
            if not(obj.preproc.ready())
                obj.preproc.setup(dataset.statsample());
            end
            % initialize base of model
            if not(obj.ready())
                frmdim = obj.preproc.dimout();
                if isnan(frmdim)
                    frmdim = dataset.dimout();
                end
                obj.initBase(frmdim);
            end
        end

        function tof = ready(obj)
            tof = obj.preproc.ready() && ~isempty(obj.base);
        end

        function n = dimin(obj)
            assert(obj.ready(), ...
                '[%s] has not been initialized, please initialize it with function SETUP.', ...
                upper(class(obj)));
            if isnan(obj.preproc.dimin()) && isnan(obj.preproc.dimout())
                n = size(obj.base, 1);
            else
                n = obj.preproc.dimin();
            end
        end

        function n = dimout(obj)
            n = obj.nbase;
        end
    end
    % ================= LEARNINGMODULE IMPLEMENTATION =================
    methods
        function learn(obj, sample)
            assert(obj.ready(), ...
                '[%s] has not been initialized, please initialize it with function SETUP.', ...
                upper(class(obj)));
            % pre-processing
            sample = obj.preproc.proc(sample);
            % generate initial responds
            respond = obj.initRespond(sample);
            % update model by learning from sample
            for i = 1 : obj.updatePerSample
                respond = obj.infer(sample, respond);
                obj.adapt(sample, respond);
            end
        end

        function train(obj, dataset)
            % ensure necessary paramter have been setup
            if ~obj.ready(), obj.setup(dataset); end
            % check compatibility of dataset and learning module
            assert(isnan(obj.dimin()) || any(obj.dimin() == dataset.dimout), ...
                '[%s] dimensionality of dataset does not match', ...
                upper(class(obj)));
            % train model by given dataset
            switch lower(obj.trainingMethod)
                case {'minibatch', 'stochastic'}
                    obj.miniBatch(dataset);
                otherwise
                    error('unrecognized training method : %s', obj.trainingMethod);
            end
            % save object
            obj.autosave(true);
        end

        function info(obj)
            fprintf('Learning Iteration [%d] Completed\n', obj.count);
        end

        H = status(obj)
    end
    % ================= GPUMODULE IMPLEMENTATION =================
    methods
        function activateGPU(obj)
            obj.preproc.activateGPU();
        end
        function deactivateGPU(obj)
            obj.preproc.deactivateGPU();
        end
    end

    % ================= INTERFACES FOR SUBCLASS =================
    methods (Abstract)
        % ### frmdim ----> (initBase) --update--> [obj]
        initBase(obj, frmdim)
        % ### sample ----> (initRespond) ----> respond
        respond = initRespond(obj, sample)
        % ### sample ----> (infer) ----> respond
        respond = infer(obj, sample, start)
        % GENERATE is the essential function that implement the generative
        % model as a program. This function would represent the generative
        % model that construct motion materials by given underlying
        % coefficients, which we called RESPOND in the program
        % ### respond ----> (generate) ----> sample
        sample = generate(obj, respond)
        % ### sample + respond ----> (adapt) --update--> [obj]
        adapt(obj, sample, respond)
        % UPDATE modify the model with given modification, while it
        % should adjust the model according to it characteristic.
        % ### delta ----> (update) --update--> [obj]
        update(obj, delta)
        % EVALUATE evaluate the performance of motion representation model
        % over given data and responds of the model. ERR should worked as
        % an optional parameter. When it is missing, EVALUATE should
        % calculate the error by itself.
        % ### sample + respond ----> (evalue) ----> objval
        objval = evaluate(obj, sample, respond)
        % MODELGRADIENT and RESPONDGRADIENT calculate derivatives of model
        % and reponds in mathematical form and return the gradients
        % accordingly.
        % ### sample + respond ----> (modelGradient) ----> mgrad
        mgrad = modelGradient(obj, sample, respond)
        % ### sample + respond ----> (respondGradient) ----> rgrad
        rgrad = respondGradient(obj, sample, respond)
    end

    % ================= TRANING METHOD =================
    methods (Access = protected)
        % learn through mini-batch to adapt model sample by sample
        function miniBatch(obj, dataset)
            for i = 1 : obj.traversePerTrain
                targetCount = obj.count + dataset.volumn();
                while obj.count < targetCount
                    % fetch data sample from dataset
                    sample = dataset.next(obj.samplePerBatch);
                    % involve model by learn sample
                    obj.learn(sample);
                    % count iteration
                    obj.count = obj.count + obj.samplePerBatch;
                    % show information and save current status
                    if obj.autosave(obj.count)
                        fprintf('%s : ITERATION %d COMPLETE @ %s\n', ...
                            upper(class(obj)), obj.count, obj.timestamp());
                    end
                end
            end
            obj.autosave(true);
            fprintf('TRAINING PROCESS FINISHED @ %s\n', obj.timestamp());
        end
    end

    % ================= DATA STRUCTURE =================
    properties (Abstract)
        base % [MATRIX] complex bases
        nbase % number of base functions
    end
    properties
        count = 0;
        % ------- PREPROCESSING MODULE -------
        preproc % preprocessor of model, DPStack is recommended
        % ------- LEARN -------
        updatePerSample = 1;
        % ------- LEARNING ALGORITHM -------
        traversePerTrain = 3;
        samplePerBatch = 1;
        % ------- LEARNING MODULE IMPLEMENTATION -------
        trainingMethod = 'minibatch';
    end

    % ================= UTILITY =================
    methods
        function obj = GenerativeModel()
            obj.preproc = DPStack();
        end
    end
end
