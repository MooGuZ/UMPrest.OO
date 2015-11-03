% CLASS : MotionLearner
%
% Basic class of UMPress.OO package that implement fundamental workflow control
% of motion representation learning process. Concrete models should be defined
% as subclasses to implement required interfaces.
%
% MooGu Z. <hzhu@case.edu>
%
% Sept 30, 2015 - initial commit

classdef MotionLearner < hgsetget
    properties
        nEpoch = 3;
        unitInBatch = 1;
        iterOfTraining = 0;
        saveEvery = 5000;
        savePath
        
        % optimiation options
        adaptOption = struct( ...
            'nIterPerTurn', 1, ...
            'step', 1e-4);
        inferOption = struct( ...
            'Method', 'bb', ...
            'Display', 'off', ...
            'MaxIter', 15, ...
            'MaxFunEvals', 20);
    end

    properties (Access = protected)
        timestamp = @() datestr(now, 30);
    end

    methods
        % constructor from MotionMaterial instance
        % @@@ check existance of savePath and create folder when necessary
        function obj = MotionLearner(savePath, varargin)
            obj.savePath = savePath;
            obj.paramSetup(varargin);
        end
    end

    methods (Access = public)
        function paramSetup(obj, varargin)
            [keys, values] = propertyParse(varargin{:});
            for i = 1 : numel(keys)
                obj.set(keys{i}, values{i});
            end
        end

        function stochasticLearn(obj, dataset)
        % LEARN start a learning process over provided DATASET, which should be
        % a instance of class MotionMaterial. Related parameter setting are
        % finished in construction of this object.
            for i = 1 : obj.nEpoch % apply stochastic optimiation method here
                newTurn = false;
                while ~newTurn
                    % fetch data sample from dataset
                    [data, ffindex, newTurn] = dataset.next(obj.unitInBatch);
                    % inference and adaptation
                    respond = obj.infer(data, ffindex, obj.initialRespond(data));
                    obj.adapt(data, ffindex, respond);
                    % count iteration
                    obj.iterOfTraining = obj.iterOfTraining + 1;
                    % show information and save current status
                    if rem(obj.iterOfTraining, obj.saveEvery) == 0
                        obj.showinfo();
                        obj.autosave();
                    end
                end
            end
            obj.autosave();
        end

        function EMLearn(obj, dataset)
            [data, ffindex] = dataset.all();
            respond = obj.initialRespond(data);
            for i = 1 : obj.nEpoch
                respond = obj.infer(data, ffindex, respond);
                obj.adapt(data, ffindex, respond);

                obj.iterOfTraining = obj.iterOfTraining + 1;

                if rem(obj.iterOfTraining, obj.saveEvery) == 0
                    obj.showinfo();
                    obj.autosave();
                end
            end
            obj.autosave();
        end

        % INFER is a calculation framework to calculate most possible
        % underline coefficients (RESPOND in the program) of generative
        % model. There is restriction that you have to put initial respond
        % to the function. This would support for determinant optimization
        % method for small dataset. Inference process generally utilize
        % standard optimiation method from MINFUNC library.
        function respond = infer(obj, data, ffindex, initRespond)
            % @@@ respond and initRespond here need to be vectorized to match
            % the interface of minFunc
            respond = minFunc(@obj.objfunc, initRespond, obj.inferOption, data, ffindex);
            % !!! need test the temporal function handle created in this way
        end

        function adapt(obj, data, ffindex, respond)
            % use structure adaptOption to provide unified interface for
            % different scheme of optimization process
            for i = 1 : obj.adaptOption.nIterPerTurn
                err = data - obj.generate(respond);
                mgrad = obj.modelGradient(respond, ffindex, err);
                obj.modelModify(-obj.adaptOption.step * mgrad); % need composite the size of input data
                obj.adjustAdaptStep(mgrad, err); % @@@ Interface Undetermined
            end
        end

        function [objval, rgrad] = objfunc(obj, respond, data, ffindex)
            err = data - obj.generate(respond);
            objval = obj.evaluate(respond, data, ffindex, err);
            if nargout > 1
                rgrad = obj.respondGradient(respond, ffindex, err);
            end
        end

        function autosave(obj)
            objname = inputname(1);
            eval(sprintf('%s = obj;', objname));
            save(fullfile( ...
                    obj.savePath, ...
                    sprintf('%s-ITER%d-%s.mat', objname, obj.iterOfTraining, obj.timestamp())), ...
                objname);
        end
    end

    % interfaces for subclass
    methods (Abstract)
        % LEARN acts as a switcher, which needs to make a choice between
        % EM-Algorithm and Stochastic optimization method.
        learn(obj, dataset)

        % INITIALRESPOND is a initializer that make a null respond which
        % fits all the non-contant requirements of a legitimate respond.
        % Besides, initialize the respond with a reasonable statistic
        % characteristic is even better
        respond = initialRespond(obj, data)

        % GENERATE is the essential function that implement the generative
        % model as a program. This function would represent the generative
        % model that construct motion materials by given underlying
        % coefficients, which we called RESPOND in the program
        data = generate(obj, respond)

        % EVALUATE evaluate the performance of motion representation model
        % over given data and responds of the model. ERR should worked as
        % an optional parameter. When it is missing, EVALUATE should
        % calculate the error by itself.
        objval = evaluate(obj, respond, data, ffindex, err)

        % MODELGRADIENT and RESPONDGRADIENT calculate derivatives of model
        % and reponds in mathematical form and return the gradients
        % accordingly.
        mgrad = modelGradient(obj, respond, ffindex, err)
        rgrad = respondGradient(obj, respond, ffindex, err)

        % MODELMODIFY modify the model with given modification, while it
        % should adjust the model according to it characteristic.
        modelModify(obj, modelDelta)

        % ADJUSTADAPTSTEP make adjustment to the step size utilized in
        % adaptation process of model.
        adjustAdaptStep(obj, mgrad, err)

        % SHOWINFO list the related information of current status of the
        % model to console, which is very important for debuging and
        % research.
        showinfo(obj)
    end
end
