classdef CustomTask < Task
    methods
        function modeldump = run(obj, nepoch, batchPerEpoch, batchsize, validsize)
            startIter = obj.iteration;
            % setup optimizer
            opt = HyperParam.getOptimizer();
            opt.gradmode('basic');
            opt.stepmode('adapt', 'estimatedChange', 1e-2);
            opt.enableRcdmode(3);
            % create validate set
            % [validset.data, validset.label] = obj.dataset.next(validsize);
            if obj.dataset.islabelled
                [validset.data, validset.label] = obj.dataset.next(validsize);
            else
                validset = obj.dataset.next(validsize);
            end
            % run model on all samples of validset and display objective value
            if obj.dataset.islabelled
                obj.dataset.data.send(validset.data);
                obj.dataset.label.send(validset.label);
            else
                obj.dataset.data.send(validset);
            end
            obj.model.forward();
            objval = obj.objective.evaluate() + sum(cellfun(@evaluate, obj.priors));
            fprintf('[%s] Initial objective value : %.2e\n', datestr(now), objval);
            opt.record(objval, false);
            % main loop
            for epoch = 1 : nepoch
                for i = 1 : batchPerEpoch
                    obj.dataset.next(batchsize);
                    obj.model.forward();
                    obj.objective.delta();
                    obj.model.backward();
                    obj.model.update();
                end
                obj.iteration = obj.iteration + batchPerEpoch;
                if obj.dataset.islabelled
                    obj.dataset.data.send(validset.data);
                    obj.dataset.label.send(validset.label);
                else
                    obj.dataset.data.send(validset);
                end
                obj.model.forward();
                objval = obj.objective.evaluate() + sum(cellfun(@evaluate, obj.priors));
                fprintf('[%s] Objective Value after [%04d] iterations : %.2e\n', ...
                    datestr(now), obj.iteration, objval);
                opt.record(objval, false);
                modeldump = obj.model.dump();
                save(fullfile(obj.savedir, sprintf(obj.namePattern, obj.iteration)), ...
                    'modeldump', '-v7.3');
            end
            % delete temporary saves
            for epoch = 1 : nepoch - 1
                niter = startIter + epoch * batchPerEpoch;
                delete(fullfile(obj.dir, sprintf(obj.namePattern, niter)));
            end
        end
    end
    
    methods
        function obj = CustomTask(taskid, taskdir, model, dataset, objective, priors, varargin)
            conf = Config(varargin);
            % setup fundamental properties
            obj.id        = taskid;
            obj.dir       = taskdir;
            obj.model     = model;
            obj.dataset   = dataset;
            obj.objective = objective;
            obj.priors    = priors;
            obj.iteration = conf.pop('iteration', 0);
            % setup dependent properties
            obj.savedir = fullfile(obj.dir, 'records');
            obj.namePattern = [obj.id, '-ITER%d-DUMP.mat'];
        end
    end
    
    properties (SetAccess = protected)
        id, iteration, dir, savedir, namePattern, priors
    end
    methods
        function set.id(obj, value)
            assert(ischar(value), 'ILLEGAL ASSIGNMENT');
            obj.id = value;
        end
        
        function set.iteration(obj, value)
            assert(MathLib.isinteger(value) && value >= 0, 'ILLEGAL ASSIGNMENT');
            obj.iteration = value;
        end
        
        function set.dir(obj, value)
            if not(isdir(value))
                [success, message, messageid] = mkdir(value);
                if not(success)
                    error(messageid, 'Directory Creation Failed: %s', message);
                end
                % create subfolders
                mkdir(value, 'records');
            end
            obj.dir = value;
        end
        
        function set.priors(obj, value)
            if isa(value, 'Prior')
                obj.priors = {value};
            else
                assert(iscell(value), 'ILLEGAL ASSIGNMENT');
                obj.priors = value;
            end
        end
    end
end
