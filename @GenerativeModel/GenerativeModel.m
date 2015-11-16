% CLASS : GenerativeModel
%
% Basic class of UMPress.OO package that implement fundamental workflow control
% of motion representation learning process. Concrete models should be defined
% as subclasses to implement required interfaces.
%
% MooGu Z. <hzhu@case.edu>
%
% Sept 30, 2015 - initial commit

classdef GenerativeModel < DPModule & LearningModule & LibExperiment & LibUtility & LibProbability
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function respond = proc(obj, sample)
            respond = obj.infer(obj.preproc.proc(sample));
        end

        function sample = invp(obj, respond)
            sample = obj.preproc.invp(obj.generate(respond));
        end

        function setup(obj, dataset)
            if not(obj.preproc.ready()), obj.preproc.setup(dataset); end
            if not(obj.ready()), obj.initBase(dataset); end
        end

        function tof = ready(obj)
            tof = obj.preproc.ready() && ~isempty(obj.base);
        end

        function n = dimin(obj)
            assert(obj.ready());
            if isnan(obj.preproc.dimin()) && isnan(obj.preproc.dimout())
                n = size(obj.base, 1);
            else
                n = obj.preproc.dimin();
            end
        end

        function n = dimout(obj)
            assert(obj.ready());
            n = obj.nbase;
        end
    end
    % ================= LEARNINGMODULE IMPLEMENTATION =================
    methods
        function learn(obj, sample)
            respond = obj.infer(obj.preproc.proc(sample));
            obj.adapt(sample, respond);
        end

        function learn(obj, sample)
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
            % train model by given dataset
            switch lower(obj.trainingMethod)
                case {'minibatch', 'stochastic'}
                    obj.miniBatch(dataset);
                otherwise
                    error('unrecognized training method : %s', obj.trainingMethod);
            end
        end

        function info(obj)
            fprintf('Learning Iteration [%d] Completed\n', obj.count);
        end

        status(obj)
    end
    % ================= OTHER PUBFUNCTION =================
    methods
        function gradchk(obj)
        end
    end

    % ================= INTERFACES FOR SUBCLASS =================
    methods (Abstract)
        % ### dataset -> (initBase) --update--> [obj]
        initBase(obj, dataset)

        % ### sample -> (initRespond) ----> respond
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

    % ================= LEARNING ALGORITHM =================
    methods (Access = protected)
        % learn through mini-batch to adapt model sample by sample
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
        % % learn model by Estimate-Modify mechanism
        % function EMAlgo(obj, dataset)
        %     sample = obj.preproc.proc(dataset.traverse());
        %     respond = obj.initialRespond(sample);
        %     for i = 1 : obj.nLearningEpoch
        %         respond = obj.infer(sample, respond);
        %         obj.adapt(sample, respond);
        %         obj.count = obj.count + dataset.volumn();
        %         obj.autosave();
        %         obj.info();
        %     end
        % end
    end

    % ================= DATA STRUCTURE =================
    properties
        count = 0;
        % ------- LEARN -------
        updatePerSample = 1;
        % ------- LEARNING ALGORITHM -------
        traversePerTrain = 3;
        samplePerBatch = 1;
        % ------- LEARNING MODULE IMPLEMENTATION -------
        trainingMethod = 'minibatch';
        % ------- PREPROCESSING MODULE -------
        preproc = DPStack(); % preprocessor of model, DPStack is recommended
    end

    % ================= UTILITY =================
    methods
        function consistencyCheck(obj)

        end
    end
end
