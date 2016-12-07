classdef Trainer < handle
    methods (Static)
        function conf = getConfig(trainMethod)
            param = UMPrest.parameter();
            switch lower(trainMethod)
                case {'minibatch'}
                  conf = Config( ...
                      'divisionRatio',    [0.6, 0.1, 0.3], ...
                      'epoch',            param.get('epoch', 10), ...
                      'batchsize',        param.get('batchsize', 32), ...
                      'validateInterval', param.get('validateInterval', 1000));
            end
        end
    end
    
    methods (Static)
        function varargout = minibatch(model, dataset, varargin)
            conf = Trainer.getConfig('minibatch');
            conf.update(varargin{:});
            % PROBLEM: cannot deal with unlimited data source
            [trainset, validset, testset] = dataset.subsets(conf.get('divisionRatio'));
            % gather validate and test data
            vdata = validset.next(validset.volumn());
            tdata = testset.next(testset.volumn());
            
            log = Logger(model, conf.get('displayMode', 'shell'));
            log.initRecord('ValidSet', vdata, 'interval', conf.get('validateInterval'));
            log.initRecord('TestSet', tdata);
           
            for ep = 1 : conf.get('epoch')
                for bat = 1 : ceil(trainset.volumn() / conf.get('batchsize'))
                    model.trainproc(trainset.next(conf.get('batchsize')));
                    log.record('ValidSet', vdata); 
                    % TBC : modify model parameters according to validation result
                end
                log.record('TestSet', tdata);
            end
            
            if nargout > 0
                varargout{1} = log;
            end
        end
        
        function trainGUnit(unit, dataset, batchsize, niter, nepoch, savepath)
            v = Vectorizer();
            for ep = 1 : nepoch
                fprintf('Learning '); infotag = 0.1;
                for iter = 1 : niter
                    unit.learn(v.transform(dataset.next(batchsize)));
                    if iter / niter >= infotag
                        infotag = infotag + 0.1;
                        fprintf('.');
                    end
                end
                unit.save(fullfile(savepath, ['GUnit-', num2str(unit.age), '.mat']));
                fprintf(' Iteration %d DONE @ %s\n', unit.age, datestr(now()));
            end
        end
    end
    
    methods
        function log = suptrain(obj, model, datasets, objectives, varargin)
            datasets   = typeAssert(datasets, 'cell');
            objectives = typeAssert(objectives, 'cell');
            Config(varargin).apply(obj);
            % prepare training process
%             obj.trainPrepare(model, datasets, objectives);
            % generate logger
            log = Logger(model, datasets, objectives, obj, varargin{:});
            % training process
            iter   = 0;
            nbatch = ceil(max(cellfun(@(ds) ds.volumn() / obj.batchsize), datasets));
            for epoch = 1 : obj.nepoch
                for batch = 1 : nbatch
                    % generate data batches
                    for i = 1 : numel(datasets)
                        datasets{i}.next(obj.batchsize);
                    end
                    % forward data pass
                    model.forward();
                    % objective evaluation and generate gradient
                    if rem(iter, obj.iterationPerRecord) == 0
                        log.record( ...
                            sum(cellfun(@evaluate, objectives)), ...
                            model.prior(), now(), iter);
                    end
                    for i = 1 : numel(objectives)
                        objectives{i}.delta();
                    end
                    % backward gradient pass
                    model.backward();
                    % update model
                    model.update();
                    % increase iteration indicator
                    iter = iter + 1;
                    % save model
                    if rem(iter, obj.iterationPerSave) == 0
                        model.save(iter);
                    end
                end
            end
            model.save(iter)
            model.savelog(log);
        end
        
        function log = unsuptrain(obj, model, datasets, objectives, varargin)
            datasets   = typeAssert(datasets, 'cell');
            objectives = typeAssert(objectives, 'cell');
            Config(varargin).apply(obj);
            % prepare training process
            % PRB: may need post configuration if the preparing process
            %      modified the model
            obj.trainPrepare(model, datasets, objectives);
            % generate logger
            log = Logger(model, datasets, objectives, obj, varargin{:});
            % training process
            iter   = 0;
            nbatch = ceil(max(cellfun(@(ds) ds.volumn() / obj.batchsize), datasets));
            for epoch = 1 : obj.nepoch
                for batch = 1 : nbatch
                    % generate data batches
                    for i = 1 : numel(datasets)
                        datasets{i}.next(obj.batchsize);
                    end
                    % data pass
                    model.forward();
                    for i = 1 : numel(model.O)
                        model.O(i).push(model.O(i).state.package);
                    end
                    model.backward();
                    % objective evaluation and generate gradient
                    if rem(iter, obj.iterationPerRecord) == 0
                        log.record( ...
                            sum(cellfun(@evaluate, objectives)), ...
                            model.prior(), now(), iter);
                    end
                    for i = 1 : numel(objectives)
                        objectives{i}.delta();
                    end
                    % gradient pass
                    model.forward();
                    % update model
                    model.update();
                    % increase iteration indicator
                    iter = iter + 1;
                    % save model
                    if rem(iter, obj.iterationPerSave) == 0
                        model.save(iter);
                    end
                end
            end
            model.save(iter)
            model.savelog(log);
        end
    end
    
    methods
        function trainPrepare(model, datasets, objectives)
        end
    end
    
    properties
        nepoch, batchsize
        iterationPerRecord, iterationPerSave
    end
end
