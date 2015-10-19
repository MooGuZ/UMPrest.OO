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
        nEpoch = 10;
        unitInBatch = 1;
        iterOfTraining = 0;
        saveEvery = 5000;
        savePath = './';
    end
    
    methods
        % constructor from MotionMaterial instance
        function obj = MotionLearner(motionDataset, savePath)
            % ! add parameter process mechanism
            obj.learningDataset = motionDataset;
            if exist('savePath', 'var')
                obj.savePath = savePath;
            end
        end
        
        function stochasticLearn(obj, dataset)
        % LEARN start a learning process over provided DATASET, which should be 
        % a instance of class MotionMaterial. Related parameter setting are
        % finished in construction of this object.
            for i = 1 : obj.nEpoch % apply stochastic optimiation method here
                data = dataset.next(obj.unitInBatch); % data have to be able to contain multiple sequences
                while ~isnan(data)
                    respond = obj.infer(data, obj.initialRespond());
                    obj.adapt(data, respond);
                    
                    obj.iterOfTraining = obj.iterOfTraining + 1; 
                    
                    if rem(obj.iterOfTraining, obj.saveEvery) == 0
                        obj.showinfo();
                        obj.autosave();
                    end
                    
                    data = dataset.next(obj.unitInBatch);
                end
            end
        end
        
        function EMLearn(obj, dataset)
            data = dataset.all();
            respond = obj.initialRespond();
            for i = 1 : obj.nEpoch
                respond = obj.infer(data, respond);
                obj.adapt(data, respond);
                
                obj.iterOfTraining = obj.iterOfTraining + 1;
                
                if rem(obj.iterOfTraining, obj.saveEvery) == 0
                    obj.showinfo();
                    obj.autosave();
                end
            end
        end
        
        % INFER is a calculation framework to calculate most possible
        % underline coefficients (RESPOND in the program) of generative
        % model. There is restriction that you have to put initial respond
        % to the function. This would support for determinant optimization
        % method for small dataset. Inference process generally utilize
        % standard optimiation method from MINFUNC library.
        function respond = infer(obj, initRespond, data)
            % @@@ respond and initRespond here need to be vectorized to match
            % the interface of minFunc
            respond = minFunc(@obj.objfunc, initRespond, obj.inferOption, data); % !!! need test the temporal interface created in this way
        end
        
        function adapt(obj, respond, data)
            % use structure adaptOption to provide unified interface for
            % different scheme of optimization process
            for i = 1 : obj.adaptOption.nIterPerTurn
                err = data - obj.generate(respond);
                mgrad = obj.modelGradient(obj, data, err);
                obj.adjustAdaptStep(mgrad, err); % @@@ interface is undetermined
                obj.modelModify(-obj.adaptOption.step * mgrad);
            end
        end
        
        function [objval, rgrad] = objfunc(obj, respond, data)
            err = data - obj.generate(respond);
            objval = obj.evaluate(respond, data, err);
            if nargout > 1
                rgrad = obj.respondGradient(respond, data, err);
            end
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
        respond = initialRespond(obj)
        
        % GENERATE is the essential function that implement the generative
        % model as a program. This function would represent the generative
        % model that construct motion materials by given underlying
        % coefficients, which we called RESPOND in the program
        data = generate(obj, respond)
        
        % EVALUATE evaluate the performance of motion representation model
        % over given data and responds of the model. ERR should worked as
        % an optional parameter. When it is missing, EVALUATE should
        % calculate the error by itself.
        objval = evaluate(obj, respond, data, err)
        
        % MODELGRADIENT and RESPONDGRADIENT calculate derivatives of model
        % and reponds in mathematical form and return the gradients
        % accordingly.
        mgrad = modelGradient(obj, data, err)
        rgrad = respondGradient(obj, respond, data, err)
        
        % MODELMODIFY modify the model with given modification, while it
        % should adjust the model according to it characteristic. 
        modelModify(obj, modelDelta)
    end
end
