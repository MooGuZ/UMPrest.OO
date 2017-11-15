classdef CustomTask < Task
    methods
        function run(obj, nepoch, batchPerEpoch, batchsize, validsize)
            if iscell(obj.dataset)
                validset = cell(1, numel(obj.dataset));
                for i = 1 : numel(validset)
                    if obj.dataset{i}.islabelled
                        [validset{i}.data, validset{i}.label] = obj.dataset{i}.next(validsize);
                    else
                        validset{i} = obj.dataset{i}.next(validsize);
                    end
                end
            else
                if obj.dataset.islabelled
                    [validset.data, validset.label] = obj.dataset.next(validsize);
                else
                    validset = obj.dataset.next(validsize);
                end
            end
            % run model on all samples of validset and display objective value
            obj.validate(validset);
            % main loop
            for epoch = 1 : nepoch
                for i = 1 : batchPerEpoch
                    if iscell(obj.dataset)
                        for j = 1 : numel(obj.dataset)
                            obj.dataset{j}.next(batchsize);
                        end
                    else
                        obj.dataset.next(batchsize);
                    end
                    if not(isempty(obj.prevnet))
                        obj.prevnet.forward();
                    end
                    obj.model.forward();
                    if not(isempty(obj.postnet))
                        obj.postnet.forward();
                    end
                    for j = 1 : numel(obj.objective)
                        obj.objective{j}.delta();
                    end
                    if not(isempty(obj.errgen))
                        obj.errgen.next(batchsize);
                    end
                    if not(isempty(obj.postnet))
                        obj.postnet.backward();
                    end
                    obj.model.backward();
                    obj.model.update();
                end
                obj.iteration = obj.iteration + batchPerEpoch;
                obj.validate(validset);
                obj.save();
            end
            % keep the last save
            obj.latestSave = [];
        end
        
        function modeldump = save(obj)
            if not(obj.nosave)
                modeldump = obj.model.dump();
                savefile  = fullfile(obj.savedir, sprintf(obj.namePattern, obj.iteration));
                save(savefile, 'modeldump', '-v7.3');
                % delete latest save
                if not(isempty(obj.latestSave))
                    delete(obj.latestSave);
                end
                % records current save as latest save
                obj.latestSave = savefile;
            end
        end
        
        function value = validate(obj, validset)
            if iscell(validset)
                for i = 1 : numel(validset)
                    if isstruct(validset{i})
                        obj.dataset{i}.data.send(validset{i}.data);
                        obj.dataset{i}.label.send(validset{i}.label);
                    else
                        obj.dataset{i}.data.send(validset{i});
                    end
                end
            else
                if isstruct(validset)
                    obj.dataset.data.send(validset.data);
                    obj.dataset.label.send(validset.label);
                else
                    obj.dataset.data.send(validset);
                end
            end
            if not(isempty(obj.prevnet))
                obj.prevnet.forward();
            end
            obj.model.forward();
            if not(isempty(obj.postnet))
                obj.postnet.forward();
            end
            value = sum(cellfun(@evaluate, obj.objective)) + sum(cellfun(@evaluate, obj.priors));
            if obj.verbose
                fprintf('[%s] Objective Value after [%04d] iterations : %.2e ', ...
                    datestr(now), obj.iteration, value);
                if obj.optimizer.cache.rcdmode.status
                    obj.optimizer.record(value);
                    fprintf('[ESTCH : %.2e]\n', obj.optimizer.cache.stepmode.estch);
                else
                    fprintf('\n');
                end
            end
        end
    end
    
    methods
        function obj = CustomTask(taskid, taskdir, model, dataset, objective, priors, varargin)
            conf = Config(varargin);
            % setup fundamental properties
            obj.id        = taskid;
            obj.dir       = abspath(taskdir);
            obj.model     = model;
            obj.dataset   = dataset;
            if iscell(objective)
                obj.objective = objective;
            else
                obj.objective = {objective};
            end
            obj.priors    = priors;
            obj.iteration = conf.pop('iteration', 0);
            obj.nosave    = conf.pop('nosave', false);
            obj.verbose   = conf.pop('verbose', true);
            % setup dependent properties
            obj.savedir     = fullfile(obj.dir, 'records');
            obj.namePattern = [obj.id, '-ITER%d-DUMP.mat'];
            % other parameters
            obj.prevnet     = conf.pop('prevnet', []);
            obj.postnet     = conf.pop('postnet', []);
            obj.errgen      = conf.pop('errgen', []);
            obj.latestSave  = [];
        end
    end
    
    properties
        nosave, verbose
    end
    properties (SetAccess = protected, Hidden)
        latestSave
    end
    properties (SetAccess = protected)
        id, iteration, dir, savedir, namePattern, priors, 
        prevnet, postnet, errgen
    end
    properties (Constant)
        optimizer = HyperParam.getOptimizer()
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
        
        function set.nosave(obj, value)
            assert(islogical(value), 'ILLEGAL ASSIGNMENT');
            obj.nosave = value;
        end
        
        function set.verbose(obj, value)
            assert(islogical(value), 'ILLEGAL ASSIGNMENT');
            obj.verbose = value;
        end
    end
end
