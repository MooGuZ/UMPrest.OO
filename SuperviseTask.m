classdef SuperviseTask < handle
    methods
        function [objval, modeldump] = run(obj, nepoch, batchsize, batchPerEpoch, validsize)
            startIter = obj.iteration;
            % setup optimizer
            opt = HyperParam.getOptimizer();
            opt.gradmode('basic');
            opt.stepmode('adapt', 'estimatedChange', 1e-2);
            opt.enableRcdmode(3);
            % create validate set
            [validset.data, validset.label] = obj.dataset.next(validsize);
            % display current status of estimation
            objval = obj.objective.evaluate(obj.model.forward(validset.data), validset.label);
            fprintf('[%s] Initial objective value : %.2e\n', datestr(now), objval);
            opt.record(objval, false);
            % main loop
            for epoch = 1 : nepoch
                for i = 1 : batchPerEpoch
                    [data, label] = obj.dataset.next(batchsize);
                    data = obj.model.forward(data);
                    obj.model.backward(obj.objective.delta(data, label));
                    obj.model.update();
                end
                obj.iteration = obj.iteration + batchPerEpoch;
                objval = obj.objective.evaluate(obj.model.forward(validset.data), validset.label);
                fprintf('[%s] Objective Value after [%04d] iterations : %.2e\n', ...
                    datestr(now), obj.iteration, objval);
                opt.record(objval, false);
                modeldump = obj.model.dump();
                save(fullfile(obj.dir, sprintf(obj.namePattern, obj.iteration)), ...
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
        function obj = Task(taskid, taskdir, model, dataset, objective, varargin)
            conf = Config(varargin);
            % setup fundamental properties
            obj.id        = taskid;
            obj.dir       = taskdir;
            obj.model     = model;
            obj.dataset   = dataset;
            obj.objective = objective;
            obj.iteration = conf.pop('iteration', 0);
            % setup dependent properties
            obj.savedir = fullfile(obj.dir, 'records');
            obj.namePattern = [obj.id, '-ITER%d-DUMP.mat'];
        end
    end
    
    properties (SetAccess = protected)
        id, iteration, dir, savedir, namePattern
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
    end
end
